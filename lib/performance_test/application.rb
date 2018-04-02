# frozen_string_literal: true

require 'logger'
require 'open3'
require 'tmpdir'
require 'json'
require 'mysql2'
require_relative 'shell_commands'

# The starting point and controll class for all the application logic
class Application
  attr_reader :log

  include ShellCommands

  def initialize
    $stdout.sync = true
    @log = Logger.new($stdout)
    @log.level = Logger::INFO
    @log.progname = File.basename($PROGRAM_NAME)
    @log.formatter = lambda do |severity, datetime, progname, msg|
      "#{datetime.strftime('%F %R')} #{progname} #{severity}: #{msg}\n"
    end
  end

  # Starts the execution of the system test
  # rubocop:disable Metrics/MethodLength
  def run
    @log.info('Starting the system test')
    config = read_configuration
    begin
      if config.create_vms?
        setup_vm(config)
        config_path = "#{@mdbci_config}_network_config"
      else
        config_path = config.server_config
      end
      machine_config = MachineConfig.new(config_path)
      configure_machines(machine_config, config) unless config.already_configured
      run_test(config, machine_config)
    rescue StandardError => error
      @log.error("Caught error: #{error.class}")
      @log.error(error.message)
      @log.error(error.backtrace.join("\n"))
    end
    destroy_vm(config) if config.create_vms? && !config.keep_servers
  end
  # rubocop:enable Metrics/MethodLength

  private

  # Parse configuration parameters and configure logger
  # @return [Configuration] read configuration
  def read_configuration
    config = Configuration.parse_parameters(@log)
    exit 1 unless config.correct?
    @log.level = Logger::DEBUG if config.verbose
    config
  end

  # Create virtual machines using the MDBCI and provided configuration.
  #
  # @param config [Configuration] configuration to use during creation.
  # @return name of the configuration that is being used.
  def setup_vm(config)
    @log.info('Creating VMs using MDBCI')
    current_time = Time.now.strftime('%Y%m%d-%H%M%S')
    @mdbci_config = "#{config.mdbci_vm_path}/#{current_time}-performance-test"
    mdbci_template = "#{@mdbci_config}.json"
    @log.info("Creating MDBCI configuration template #{mdbci_template}")
    TemplateGenerator.generate("#{PerformanceTest::MDBCI_TEMPLATES}/machines.json.erb", mdbci_template.to_s, config.internal_binding)
    @log.info("Generating MDBCI configuration #{@mdbci_config}")
    result = run_command_and_log("#{config.mdbci_tool} generate --template #{mdbci_template} #{@mdbci_config}")
    raise 'Could not create MDBCI configuration' unless result[:value].success?
    @log.info('Creating VMs with MDBCI')
    run_command_and_log("#{config.mdbci_tool} up #{@mdbci_config}")
  end

  # Destroy MDBCI virtual machines
  #
  # @param config [Configuration] configuration to use during destroy.
  def destroy_vm(config)
    @log.info('Destroying VMs created with MDBCI')
    run_command_and_log("#{config.mdbci_tool} destroy #{@mdbci_config}")
  end

  # Configure all machines with their respected role
  #
  # @param machine_config [MachineConfig] information about network configuration of machines
  # @param config [Configuration] confuguration to use during machine configuration
  def configure_machines(machine_config, config)
    @log.info('Configuring machines')
    configurator = MachineConfigurator.new(@log)
    configure_with_chef_mariadb(machine_config.configs['node_000'], configurator, config)
    configure_backend_servers(machine_config.configs['node_000'], config, machine_config)
    configure_with_chef_maxscale(machine_config.configs['maxscale'], configurator, config)
    configure_maxscale_server(machine_config.configs['maxscale'], configurator, config, machine_config)
    create_test_database(machine_config.configs['maxscale']['network'])
  end

  # Configure maxscale server machine with the Chef recipie
  # @param machine [Hash] parameters of machine to connect to.
  # @param configurator [MachineConfigurator] reference to the configurator.
  # @param config [Configuration] configuration of the tool.
  def configure_with_chef_maxscale(machine, configurator, config)
    @log.info('Configuring maxscale machine')
    Dir.mktmpdir('performance-test') do |dir|
      maxscale_role = "#{dir}/maxscale-host.json"
      ubuntu_release = configurator.run_command(machine, 'lsb_release -c | cut -f2').strip
      maxscale_version = config.maxscale_version
      TemplateGenerator.generate("#{PerformanceTest::CHEF_ROLES}/maxscale-host.json.erb", maxscale_role, binding)
      configurator.configure(machine, 'maxscale-host.json',
                             [[maxscale_role, 'roles/maxscale-host.json']])
    end
  end

  # Configure maxscale with the proposed configuration file
  # @param machine [Hash] parameters of server to connect to
  # @param configurator [MachineConfigurator] reference to the configurator.
  # @param config [Configuration] reference to the configuration.
  # @param machine_config [MachineConfig] configuation of machines to use
  def configure_maxscale_server(machine, configurator, config, machine_config)
    @log.info('Configuring MaxScale server')
    Dir.mktmpdir('performance-test') do |dir|
      maxscale_config = "#{dir}/maxscale.cnf"
      TemplateGenerator.generate(config.maxscale_config, maxscale_config, machine_config.environment_binding)
      configurator.within_ssh_session(machine) do |connection|
        configurator.sudo_exec(connection, '', 'sudo service maxscale stop')
        configurator.upload_file(connection, maxscale_config, '/tmp/maxscale.cnf')
        configurator.sudo_exec(connection, '', 'cp /tmp/maxscale.cnf /etc/maxscale.cnf')
        configurator.sudo_exec(connection, '', 'sudo service maxscale start')
      end
    end
  end

  # Create test database on the maxscale server and test that everything works
  # as expected
  # @param server [String] address of the server to connect to
  def create_test_database(server)
    @log.info('Creating test database on the server')
    attempt = 0
    begin
      client = Mysql2::Client.new(host: server, port: 4006, username: 'skysql', password: 'skysql')
    rescue Mysql2::Error => error
      @log.error('Unable to connect to MaxScale.')
      @log.error(error.message)
      attempt += 1
      if attempt < 3
        @log.info('Retrying MaxScale database connection.')
        sleep 5
        retry
      else
        @log.error('Unable to connect to MaxScale after 3 attempts.')
        raise
      end
    end
    begin
      client.query('drop database test')
    rescue Mysql2::Error => error
      @log.error('Unable to drop database test.')
      @log.error("Caugt error #{error.class}. With message:")
      @log.error(error.message)
    end
    client.query('create database test')
  end

  # Configure machine as mariadb using passed parameters.
  # @param machine [Hash] parameters of machine to connect to.
  # @param configurator [MachineConfigurator] reference to the configurator.
  # @param config [Configuration] configuration of the tool.
  def configure_with_chef_mariadb(machine, configurator, config)
    @log.info('Configuring mariadb backend machine')
    repo_file = "#{config.mdbci_path}/repo.d/community/ubuntu/#{config.mariadb_version}.json"
    raise "Unable to find MariaDB configuration in '#{repo_file}'" unless File.exist?(repo_file)
    ubuntu_release = configurator.run_command(machine, 'lsb_release -c | cut -f2').strip
    mariadb_config = JSON.parse(File.read(repo_file)).find { |mariadb| mariadb['platform_version'] == ubuntu_release }
    raise "There was no configuration for '#{ubuntu_release}' in #{repo_file}" if mariadb_config.nil?
    mariadb_repository = mariadb_config['repo']
    Dir.mktmpdir('performance-test') do |dir|
      mariadb_role = "#{dir}/mariadb-host.json"
      TemplateGenerator.generate("#{PerformanceTest::CHEF_ROLES}/mariadb-host.json.erb", mariadb_role, binding)
      configurator.configure(machine, 'mariadb-host.json',
                             [[mariadb_role, 'roles/mariadb-host.json']])
    end
  end

  # Use selected SQL scripts to configure MariaDB backend servers.
  def configure_backend_servers(machine, config, machine_config)
    @log.info('Configuring MariaDB servers according to configuration')
    config.mariadb_init_scripts.each_with_index do |script_path, index|
      next if script_path.empty?
      @log.info("Configuring #{index + 1} MariaDB server using #{script_path}")
      script = TemplateGenerator.generate_string(script_path, machine_config.environment_binding)
      @log.debug("Using the script:\n#{script}")
      client = Mysql2::Client.new(host: machine['network'], port: 3301 + index, username: 'skysql', password: 'skysql')
      statements = script.gsub(/\n/, '').split(";").map(&:strip).delete_if(&:empty?)
      statements.each { |statement| client.query(statement) }
    end
  end

  # Run the test tool and provide it with the configuration.
  #
  # @param configuration [Configuration] configuration to use.
  # @param machine_config [MachineConfig] information about machines.
  def run_test(configuration, machine_config)
    unless configuration.local_test_app.empty?
      @log.info("Running the local test '#{configuration.local_test_app}'")
      result = run_command_and_log(configuration.local_test_app, false, {}, machine_config.environment_hash)
      @log.info("Test was success: #{result[:value].success?}")
    else
      @log.info("Running the remote test '#{configuration.remote_test_app}")
      configurator = MachineConfigurator.new(@log)
      configurator.within_ssh_session(machine_config.configs['maxscale']) do |connection|
        configurator.upload_file(connection, configuration.remote_test_app, '/tmp/test')
        configurator.ssh_exec(connection, 'chmod +x /tmp/test')
        configurator.ssh_exec(connection, '/tmp/test')
      end
    end
  end
end

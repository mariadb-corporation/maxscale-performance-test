# frozen_string_literal: true

require 'logger'
require 'open3'
require 'tmpdir'
require 'tempfile'
require 'fileutils'
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
    run_with_exclusive_lock(File.basename($PROGRAM_NAME)) do
      config = read_configuration
      begin
        if config.create_vms?
          setup_vm(config)
          config_path = "#{@mdbci_config}_network_config"
        else
          config_path = config.server_config
        end
        machine_config = MachineConfig.new(config_path, config.extra_arguments)
        machine_config = MachineConfig.new(config_path)
        configure_machines(machine_config, config) unless config.already_configured
        run_test(config, machine_config)
      rescue StandardError => error
        @log.error("Caught error: #{error.class}")
        @log.error(error.message)
        @log.error(error.backtrace.join("\n"))
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  # Runs signle instance of a process with unique name
  #
  # @param process_name [String] name of a running process to use in the lock file name
  def run_with_exclusive_lock(process_name)
    lock_file = "/var/lock/#{process_name}_lock"
    File.open(lock_file, 'w') do |f|
      begin
        @log.info('Taking ownership of the lock file...')
        f.flock(File::LOCK_EX)
        @log.info('Starting the system test')
        yield
      ensure
        f.flock(File::LOCK_UN)
      end
    end
  end

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
    mdbci_template = generate_mdbci_template(config)
    TemplateGenerator.generate("#{PerformanceTest::MDBCI_TEMPLATES}/machines.json.erb",
                               mdbci_template.to_s, config.internal_binding)
    @log.info("Generating MDBCI configuration #{@mdbci_config}")
    result = run_command_and_log("#{config.mdbci_tool} generate --template #{mdbci_template} #{@mdbci_config}")
    raise 'Could not create MDBCI configuration' unless result[:value].success?

    @log.info('Creating VMs with MDBCI')
    run_command_and_log("#{config.mdbci_tool} up #{@mdbci_config}")
  end

  def generate_mdbci_template(config)
    @log.info('Creating VMs using MDBCI')
    current_time = Time.now.strftime('%Y%m%d-%H%M%S')
    FileUtils.mkdir_p(config.mdbci_vm_path) unless Dir.exist?(config.mdbci_vm_path)
    @mdbci_config = "#{config.mdbci_vm_path}/#{current_time}-performance-test"
    mdbci_template = "#{@mdbci_config}.json"
    @log.info("Creating MDBCI configuration template #{mdbci_template}")
    mdbci_template
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
    @log.info('Configuring MaxScale host machine')
    Dir.mktmpdir('performance-test') do |dir|
      maxscale_role = "#{dir}/maxscale-host.json"
      ubuntu_release = configurator.run_command(machine, 'lsb_release -c | cut -f2').strip
      maxscale_version = config.maxscale_version
      TemplateGenerator.generate("#{PerformanceTest::CHEF_ROLES}/maxscale-host.json.erb", maxscale_role, binding)
      configurator.configure(machine, 'maxscale-host.json',
                             [[maxscale_role, 'roles/maxscale-host.json']])
      configurator.within_ssh_session(machine) do |connection|
        version_info = configurator.ssh_exec(connection, 'maxscale --version-full')
        @log.info("Maxscale version info:\n#{version_info}")
      end
      @log.info('Installed the following ')
    end
  end

  # Configure MaxScale with the proposed configuration file
  # @param machine [Hash] parameters of server to connect to
  # @param configurator [MachineConfigurator] reference to the configurator.
  # @param config [Configuration] reference to the configuration.
  # @param machine_config [MachineConfig] configuation of machines to use
  def configure_maxscale_server(machine, configurator, config, machine_config)
    @log.info('Configuring MaxScale server')
    maxscale_config = generate_file(config.maxscale_config, 'maxscale.cnf', machine_config.environment_binding)
    @log.info("MaxScale configuration: #{maxscale_config}")
    configurator.within_ssh_session(machine) do |connection|
      configurator.sudo_exec(connection, '', 'service maxscale stop')
      configurator.upload_file(connection, maxscale_config, '/tmp/maxscale.cnf')
      configurator.sudo_exec(connection, '', 'cp /tmp/maxscale.cnf /etc/maxscale.cnf')
      configurator.sudo_exec(connection, '', 'service maxscale start')
    end
  end

  # Generate file based on the template and environment binding
  # @param template [String] path to the template to use
  # @param file_name [String] name of the resulting file to create
  # @param environment [Binding] environment to use during the file creation
  # @return [String] path to the generated file
  def generate_file(template, file_name, environment)
    output_dir = File.join(PerformanceTest::WORKING_DIRECTORY, 'performance-test')
    Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
    result_file = "#{output_dir}/#{file_name}"
    TemplateGenerator.generate(template, result_file, environment)
    result_file
  end

  # Create test database on the MaxScale server and test that everything works
  # as expected
  # @param server_address [String] address of the server to connect to
  def create_test_database(server_address)
    @log.info('Creating test database on the server')
    client = create_database_connection(server_address)
    begin
      client.query('drop database test')
    rescue Mysql2::Error => error
      @log.error('Unable to drop database test.')
      @log.error("Caugt error #{error.class}. With message:")
      @log.error(error.message)
    end
    client.query('create database test')
  end

  # Create connection to the database server configured with the proper account
  # @param server_address [String] address of the server to connect to
  # rubocop:disable Metrics/MethodLength
  def create_database_connection(server_address)
    attempt = 0
    begin
      client = Mysql2::Client.new(host: server_address, port: 4006, username: 'skysql', password: 'skysql')
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
    client
  end
  # rubocop:enable Metrics/MethodLength

  # Configure machine as mariadb using passed parameters.
  # @param machine [Hash] parameters of machine to connect to.
  # @param configurator [MachineConfigurator] reference to the configurator.
  # @param config [Configuration] configuration of the tool.
  def configure_with_chef_mariadb(machine, configurator, config)
    @log.info('Configuring mariadb backend machine')
    repo_file = "#{Dir.home}/.config/mdbci/repo.d/mariadb/ubuntu/#{config.mariadb_version}.json"
    raise "Unable to find MariaDB configuration in '#{repo_file}'." unless File.exist?(repo_file)

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
      statements = script.delete("\n").split(';').map(&:strip).delete_if(&:empty?)
      statements.each { |statement| client.query(statement) }
    end
  end

  # Run the test tool and provide it with the configuration.
  #
  # @param configuration [Configuration] configuration to use.
  # @param machine_config [MachineConfig] information about machines.
  def run_test(configuration, machine_config)
    if configuration.remote_test_app.empty?
      @log.info("Running the local test '#{configuration.local_test_app}'")
      result = run_command_and_log(configuration.local_test_app, false, {}, machine_config.environment_hash)
      @log.info("Test was success: #{result[:value].success?}")
    else
      @log.info("Running the remote test '#{configuration.remote_test_app}")
      configurator = MachineConfigurator.new(@log)
      configurator.within_ssh_session(machine_config.configs['maxscale']) do |connection|
        test_app = generate_file(configuration.remote_test_app, 'test-app', machine_config.environment_binding)
        configurator.upload_file(connection, test_app, '/tmp/test')
        configurator.ssh_exec(connection, 'chmod +x /tmp/test')
        configurator.ssh_exec(connection, '/tmp/test')
      end
    end
  end
end

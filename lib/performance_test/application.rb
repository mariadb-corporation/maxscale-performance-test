# frozen_string_literal: true

require 'logger'
require 'open3'
require 'tmpdir'
require 'json'

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
      @log.error(error.message)
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
    TemplateGenerator.generate('mdbci-config/machines.json.erb', mdbci_template.to_s, config.internal_binding)
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
    configure_maxscale(machine_config.configs['maxscale'], configurator, config)
    configure_mariadb(machine_config.configs['node_000'], configurator, config)
  end

  # Configure maxscale according to the configuration
  # @param machine [Hash] parameters of machine to connect to.
  # @param configurator [MachineConfigurator] reference to the configurator.
  # @param config [Configuration] configuration of the tool.
  def configure_maxscale(machine, configurator, config)
    @log.info('Configuring maxscale machine')
    Dir.mktmpdir('performance-test') do |dir|
      maxscale_role = "#{dir}/maxscale-host.json"
      ubuntu_release = configurator.run_command(machine, 'lsb_release -c | cut -f2').strip
      maxscale_version = config.maxscale_version
      TemplateGenerator.generate('chef-roles/maxscale-host.json.erb', maxscale_role, binding)
      configurator.configure(machine, 'maxscale-host.json',
                            [[maxscale_role, 'roles/maxscale-host.json']])
    end
  end

  # Configure machine as mariadb using passed parameters.
  # @param machine [Hash] parameters of machine to connect to.
  # @param configurator [MachineConfigurator] reference to the configurator.
  # @param config [Configuration] configuration of the tool.
  def configure_mariadb(machine, configurator, config)
    @log.info('Configuring mariadb backend machine')
    repo_file = "#{config.mdbci_path}/repo.d/community/ubuntu/#{config.mariadb_version}.json"
    raise "Unable to find MariaDB configuration in '#{repo_file}'" unless File.exist?(repo_file)
    ubuntu_release = configurator.run_command(machine, 'lsb_release -c | cut -f2').strip
    mariadb_config = JSON.parse(File.read(repo_file)).find { |mariadb| mariadb['platform_version'] == ubuntu_release }
    raise "There was no configuration for '#{ubuntu_release}' in #{repo_file}" if mariadb_config.nil?
    mariadb_repository = mariadb_config['repo']
    Dir.mktmpdir('performance-test') do |dir|
      mariadb_role = "#{dir}/mariadb-host.json"
      TemplateGenerator.generate('chef-roles/mariadb-host.json.erb', mariadb_role, binding)
      configurator.configure(machine, 'mariadb-host.json',
                            [[mariadb_role, 'roles/mariadb-host.json']])
    end
  end

  # Run the test tool and provide it with the configuration.
  #
  # @param configuration [Configuration] configuration to use.
  # @param machine_config [MachineConfig] information about machines.
  def run_test(configuration, machine_config)
    if configuration.test_app.empty?
      @log.error('You did not specify test, doing nothing')
      return
    end
    @log.info("Running the test '#{configuration.test_app}'")
    result = run_command_and_log(configuration.test_app, false, {}, machine_config.environment_hash)
    @log.info("Test was success: #{result[:value].success?}")
  end
end

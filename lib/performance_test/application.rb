# frozen_string_literal: true

require 'logger'
require 'open3'

# The starting point and controll class for all the application logic
class Application
  def initialize
    @log = Logger.new(STDOUT)
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
    config = Configuration.parse_parameters(@log)
    @log.level = Logger::DEBUG if config.verbose
    begin
      if config.server_config.empty?
        setup_vm(config)
        config_path = "#{@mdbci_config}_network_config"
      else
        config_path = config.server_config
      end
      machine_config = MachineConfig.new(config_path)
      configure_machines(machine_config)
    rescue StandardError => error
      @log.error(error.message)
    end
    destroy_vm(config) if config.server_config.empty? && !config.keep_servers
  end
  # rubocop:enable Metrics/MethodLength

  private

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
    TemplateGenerator.generate('machines.json.erb', mdbci_template.to_s, config)
    @log.info("Generating MDBCI configuration #{@mdbci_config}")
    result = run_command("#{config.mdbci_tool} generate --template #{mdbci_template} #{@mdbci_config}")
    raise 'Could not create MDBCI configuration' unless result.success?
    @log.info('Creating VMs with MDBCI')
    run_command("#{config.mdbci_tool} up #{@mdbci_config}")
  end

  # Destroy MDBCI virtual machines
  #
  # @param config [Configuration] configuration to use during destroy.
  def destroy_vm(config)
    @log.info('Destroying VMs created with MDBCI')
    run_command("#{config.mdbci_tool} destroy #{@mdbci_config}")
  end

  # Configure all machines with their respected role
  #
  # @param config [MachineConfig] information about network configuration of machines
  def configure_machines(machine_config)
    @log.info('Configuring machines')
    configurator = MachineConfigurator.new(@log)
    maxscale = machine_config.configs['maxscale']
    mariadb = machine_config.configs['node_000']
    configurator.configure(maxscale['network'], maxscale['whoami'], maxscale['keyfile'], 'maxscale-host.json')
    configurator.configure(mariadb['network'], mariadb['whoami'], mariadb['keyfile'], 'mariadb-host.json')
  end

  # Run and log command and it's results
  #
  # @param command [String] command to execute
  def run_command(command)
    @log.info("Running command '#{command}'")
    output, result = Open3.capture2e(command)
    @log.debug("Command output:\n #{output}")
    result
  end
end

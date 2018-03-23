# frozen_string_literal: true

require 'optparse'

# This class captures the configuration for the tool.
# Configuration includes the information about the tooling.
class Configuration
  attr_accessor :backend_box, :memory_size, :mariadb_version, :mariadb_init_scripts,
                :maxscale_box, :maxscale_version, :maxscale_config,
                :mdbci_path, :mdbci_vm_path, :verbose, :server_config,
                :keep_servers, :test_app, :already_configured
  # @param logger [Logger] application logger to use
  def initialize(logger)
    @backend_box = 'ubuntu_xenial_libvirt'
    @memory_size = 2048
    @mariadb_version = '10.2'
    @mariadb_init_scripts = ['', '', '', '']
    @maxscale_box = @backend_box
    @maxscale_version = 'maxscale-2.2.3-release'
    @maxscale_config = ''
    @mdbci_path = File.expand_path('~/mdbci')
    @mdbci_vm_path = File.expand_path('~/vms')
    @verbose = false
    @server_config = ''
    @keep_servers = false
    @test_app = ''
    @already_configured = false
    @logger = logger
  end

  def to_s
    <<-DOC
    Backend MDBCI box: #{@backend_box}
    Maxscale MDBCI box: #{@maxscale_box}
    Memory size: #{@memory_size}
    MariaDB version: #{@mariadb_version}
    MariaDB init scripts: #{mariadb_init_scripts}
    MaxScale version: #{@maxscale_version}
    MaxScale configuration: #{@maxscale_config}
    MDBCI path: #{@mdbci_path}
    MDBCI VM configuration path: #{@mdbci_vm_path}
    Verbose: #{@verbose}
    Server configuration: #{@server_config}
    Keep servers: #{@keep_servers}
    Test application: #{@test_app}
    Already configured: #{@already_configured}
    DOC
  end

  # Method returns path to the mdbci executable
  def mdbci_tool
    "#{@mdbci_path}/mdbci"
  end

  # Parse arguments passed to the application, infer values and create
  # new configuration instance.
  #
  # @param logger [Logger] logger to use
  # @return [Configuration] filled-in configuration object
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/BlockLength
  def self.parse_parameters(logger)
    logger.info('Parsing command-line arguments')
    configuration = Configuration.new(logger)
    parser = OptionParser.new do |opts|
      opts.on('--backend-box=BOX', 'Name of the backend and maxscale box to use') do |box|
        configuration.backend_box = box
        configuration.maxscale_box = box
      end

      opts.on('--memory-size=SIZE', Integer, 'Amount of memory to use on virtual boxes') do |memory_size|
        configuration.memory_size = memory_size.to_i
        raise ArgumentError, 'Memory size must be positive integer' if configuration.memory_size <= 0
      end

      opts.on('--maxscale-box=BOX', 'Box to install for maxscale') do |box|
        configuration.maxscale_box = box
      end

      opts.on('--mdbci-path=PATH', 'Path to the MDBCI directory') do |path|
        configuration.mdbci_path = File.expand_path(path)
      end

      opts.on('--mdbci-vm-path=PATH', 'Directory where MDBCI configuration should be stored') do |path|
        configuration.mdbci_vm_path = File.expand_path(path)
      end

      opts.on('-v', '--verbose', TrueClass, 'Should display verbose output') do |verbose|
        configuration.verbose = verbose
      end

      opts.on('--server-config=PATH', 'Path to the servers configuration to use') do |path|
        configuration.server_config = File.expand_path(path)
      end

      opts.on('--keep-servers', TrueClass, 'Should we destroy the MDBCI machines or not when completed') do |keep|
        configuration.keep_servers = keep
      end

      opts.on('--test-app=PATH', 'Path to the test that should be executed') do |path|
        configuration.test_app = File.expand_path(path)
      end

      opts.on('--already-configured=YES', FalseClass, 'If set, the machines will not be configured') do |configured|
        configuration.already_configured = configured
      end

      opts.on('--mariadb-version=VERSION', 'Version of MariaDB to install on the backend') do |version|
        configuration.mariadb_version = version
      end

      opts.on('--maxscale-version=VERSION', 'Version of MaxScale to install onto the backend') do |version|
        configuration.maxscale_version = version
      end

      opts.on('--maxscale-config=CONFIG', 'Name of the template to use to configure MaxScale') do |config|
        configuration.maxscale_config = File.expand_path(config, PerformanceTest::MAXSCALE_TEMPLATES)
      end

      (1..4).each do |server|
        opts.on("--db-server-#{server}-config=CONFIG", "Configuration script for #{server} MariaDB server") do |config|
          configuration.mariadb_init_scripts[server - 1] = File.expand_path(config, PerformanceTest::DB_TEMPLATES)
        end
      end

      opts.on('-h', '--help', 'Print help and exit') do
        puts opts
        exit 1
      end
    end
    parser.parse(ARGV)
    logger.info("Using configuration:\n#{configuration}")
    configuration
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/BlockLength

  def internal_binding
    binding
  end

  # Checks whether the configuration file is correct.
  # @return [Boolean]
  def correct?
    correct = true
    correct ||= check_file(@maxscale_config, "Maxscale configuration file '#{@maxscale_config}' was not found")
    @mariadb_init_scripts.each_with_index do |script, index|
      next if script.empty?
      correct ||= check_file(script, "Maria DB configuration file '#{script}' for #{index} server was not found")
    end
    correct ||= check_file(@test_app, "Testing application file '#{@test_app}' was not found.")
    correct
  end

  # Specify whether it is needed to create a virtual machines with MDBCI
  # @return [Boolean] true if it is needed
  def create_vms?
    @server_config.empty?
  end

  private

  # Check that file exists, if not, display error message
  def check_file(file_name, error_message)
    return true if File.exist?(file_name)
    @logger.error(error_message)
    return false
  end
end

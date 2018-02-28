# frozen_string_literal: true

require 'optparse'

# This class captures the configuration for the tool.
# Configuration includes the information about the tooling.
class Configuration
  attr_accessor :node_count, :galera_count, :backend_box, :memory_size,
                :product, :version, :cnf_path, :maxscale_box,
                :galera_version, :mdbci_path, :mdbci_vm_path,
                :verbose, :server_config, :keep_servers, :test,
                :already_configured
  def initialize
    @node_count = 1
    @galera_count = 0
    @backend_box = 'ubuntu_xenial_libvirt'
    @memory_size = 2048
    @product = 'mariadb'
    @version = '10.2'
    @galera_version = @version
    @maxscale_box = @backend_box
    @cnf_path = File.expand_path('../BUILD/mdbci/cnf')
    @mdbci_path = File.expand_path('~/mdbci')
    @mdbci_vm_path = File.expand_path('~/vms')
    @verbose = false
    @server_config = ''
    @keep_servers = false
    @test = ''
    @already_configured = false
  end

  def to_s
    <<-DOC
    Node boxes count: #{@node_count}
    Galera boxes count: #{@galera_count}
    Backend box: #{@backend_box}
    Memory size: #{@memory_size}
    Product: #{@product}
    Product version: #{@version}
    Galera version: #{@galera_version}
    Maxscale box: #{@maxscale_box}
    Config path: #{@cnf_path}
    MDBCI path: #{@mdbci_path}
    MDBCI VM path: #{@mdbci_vm_path}
    Verbose: #{@verbose}
    Server configuration: #{@server_config}
    Keep servers: #{@keep_servers}
    Test application: #{@test}
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
    configuration = Configuration.new
    parser = OptionParser.new do |opts|
      opts.on('--node-count=COUNT', Integer, 'Number of nodes to setup') do |count|
        configuration.node_count = count.to_i
        raise ArgumentError, 'Node number must be positive' if configuration.node_count.negative?
      end

      opts.on('--galera-count=COUNT', Integer, 'Number of galera nodes to setup') do |count|
        configuration.galera_count = count.to_i
        raise ArgumentError, 'Galera nodes counter must be positive' if configuration.galera_count.negative?
      end

      opts.on('--backend-box=BOX', 'Name of the backend and maxscale box to use') do |box|
        configuration.backend_box = box
        configuration.maxscale_box = box
      end

      opts.on('--memory-size=SIZE', Integer, 'Amount of memory to use on virtual boxes') do |memory_size|
        configuration.memory_size = memory_size.to_i
        raise ArgumentError, 'Memory size must be positive integer' if configuration.memory_size <= 0
      end

      opts.on('--product=NAME', 'Name of the product to install') do |product|
        configuration.product = product
      end

      opts.on('--product-version=VERSION', 'Version of the product to install') do |version|
        configuration.version = version
        configuration.galera_version = version
      end

      opts.on('--galera-version=VERSION', 'Version of the galera to install') do |version|
        configuration.galera_version = version
      end

      opts.on('--maxscale-box=BOX', 'Box to install for maxscale') do |box|
        configuration.maxscale_box = box
      end

      opts.on('--cnf-path=PATH', 'Path to the directory containing') do |path|
        configuration.cnf_path = File.expand_path(path)
      end

      opts.on('--mdbci-path=PATH', 'Path to the MDBCI directory') do |path|
        configuration.mdbci_path = File.expand_path(path)
      end

      opts.on('--mdbci-vm-path=PATH', 'Path to the VM directory for MDBCI directory') do |path|
        configuration.mdbci_vm_path = File.expand_path(path)
      end

      opts.on('-v', '--verbose', TrueClass, 'Should display verbose output') do |verbose|
        configuration.verbose = verbose
      end

      opts.on('--server-config=PATH', 'Path to the servers configuration to use') do |path|
        configuration.server_config = File.expand_path(path)
      end

      opts.on('--keep-servers=YES', FalseClass, 'Should we destroy the MDBCI machines or not when completed') do |keep|
        configuration.keep_servers = keep
      end

      opts.on('--test=PATH', 'Path to the test that should be executed') do |path|
        configuration.test = File.expand_path(path)
      end

      opts.on('--already-configured=YES', FalseClass, 'If set, the machines will not be configured') do |configured|
        configuration.already_configured = configured
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
end

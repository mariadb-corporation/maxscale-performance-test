# frozen_string_literal: true

require 'io/console'
require 'net/ssh'
require 'net/scp'

# Class allows to configure a specified machine using the chef-solo,
# MDBCI coockbooks and roles.
class MachineConfigurator
  def initialize(logger, root_path = File.expand_path('../../../chef-repository', __FILE__))
    @log = logger
    @root_path = root_path
  end

  # rubocop:disable Metrics/ParameterLists
  def configure(address, username, key, config_name, sudo_password = '', chef_version = '13.8.0')
    @log.info("Configuring machine #{address} with #{config_name}")
    within_ssh_session(address, username, key) do |connection|
      install_chef_on_server(connection, sudo_password, chef_version)
      remote_dir = '/tmp/provision'
      copy_chef_files(connection, remote_dir, sudo_password)
      run_chef_solo(config_name, connection, remote_dir, sudo_password)
      sudo_exec(connection, sudo_password, "rm -rf #{remote_dir}")
    end
  end
  # rubocop:enable Metrics/ParameterLists

  private

  def within_ssh_session(server, user, key)
    options = Net::SSH.configuration_for(server, true)
    options[:keys] = [key]
    Net::SSH.start(server, user, options) do |ssh|
      yield ssh
    end
  end

  # rubocop:disable Metrics/MethodLength
  def sudo_exec(connection, sudo_password, command)
    @log.info("Running 'sudo -S #{command}' on the remote server.")
    output = ''
    connection.open_channel do |channel, _success|
      channel.on_data do |_, data|
        data.split("\n").reject(&:empty?).each { |line| @log.debug("ssh: #{line}") }
        output += "#{data}\n"
      end
      channel.on_extended_data do |ch, _, data|
        if data =~ /^\[sudo\] password for /
          @log.debug('ssh: providing sudo password')
          ch.send_data "#{sudo_password}\n"
        else
          @log.debug("ssh error: #{data}")
        end
      end
      channel.exec("sudo -S #{command}")
      channel.wait
    end.wait
    output
  end
  # rubocop:enable Metrics/MethodLength

  def ssh_exec(connection, command)
    @log.info("Running '#{command}' on the remote server")
    output = ''
    connection.open_channel do |channel, _success|
      channel.on_data do |_, data|
        data.split("\n").reject(&:empty?).each { |line| @log.debug("ssh: #{line}") }
        output += "#{data}\n"
      end
      channel.on_extended_data do |_, _, data|
        @log.debug("ssh error: #{data}")
      end
      channel.exec(command)
      channel.wait
    end.wait
    output
  end

  def install_chef_on_server(connection, sudo_password, chef_version)
    @log.info("Installing Chef #{chef_version} on the server.")
    output = ssh_exec(connection, 'chef-solo --version')
    if output.include?(chef_version)
      @log.info("Chef #{chef_version} is already installed on the server.")
      return
    end
    ssh_exec(connection, 'curl -s -L https://www.chef.io/chef/install.sh --output install.sh')
    sudo_exec(connection, sudo_password, "bash install.sh -v #{chef_version}")
    ssh_exec(connection, 'rm install.sh')
  end

  def copy_chef_files(connection, remote_dir, sudo_password)
    @log.info('Copying chef files to the server.')
    sudo_exec(connection, sudo_password, "rm -rf #{remote_dir}")
    ssh_exec(connection, "mkdir -p #{remote_dir}")
    %w[configs vendor-cookbooks roles solo.rb].each do |target|
      full_path = "#{@root_path}/#{target}"
      next unless File.exist?(full_path)
      @log.debug("Transferring #{target}")
      connection.scp.upload!(full_path, "#{remote_dir}/#{target}", recursive: true)
    end
  end

  def run_chef_solo(config_name, connection, remote_dir, sudo_password)
    sudo_exec(connection, sudo_password, "chef-solo -c #{remote_dir}/solo.rb -j #{remote_dir}/configs/#{config_name}")
  end
end

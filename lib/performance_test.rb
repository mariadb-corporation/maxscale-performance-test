# frozen_string_literal: true

require 'pp'

# A module for all the performance test files, provides a closure for
# the code of the application
module PerformanceTest
  require_relative 'performance_test/configuration'
  require_relative 'performance_test/application'
  require_relative 'performance_test/template_generator'
  require_relative 'performance_test/machine_configurator'
  require_relative 'performance_test/machine_config'
  require_relative 'performance_test/shell_commands'

  BASE_DIRECTORY = File.expand_path('..', __dir__).freeze
  TEMPLATES_DIRECTORY = File.expand_path('templates', BASE_DIRECTORY).freeze
  DB_TEMPLATES = File.expand_path('db-config', TEMPLATES_DIRECTORY).freeze
  MAXSCALE_TEMPLATES = File.expand_path('maxscale-config', TEMPLATES_DIRECTORY).freeze
  MDBCI_TEMPLATES = File.expand_path('mdbci-config', TEMPLATES_DIRECTORY).freeze
  CHEF_ROLES = File.expand_path('chef-roles', TEMPLATES_DIRECTORY).freeze
  WORKING_DIRECTORY = if ENV.key?('OLD_CWD')
                        ENV['OLD_CWD']
                      else
                        Dir.pwd
                      end
end

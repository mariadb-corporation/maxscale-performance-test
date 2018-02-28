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
end

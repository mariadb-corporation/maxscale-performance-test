# frozen_string_literal: true

require 'erb'

# Class allows to generate template for the MDBCI
class TemplateGenerator
  TEMPLATE_DIR = File.expand_path('../../../templates/', __FILE__)

  # Generate a configuration for MDBCI based on the template file.
  #
  # @param template_name [String] name of the template to use.
  # @param target_name [String] path to the file to be generated.
  # @param configuration [Configuration] parameters to use during the creation.
  def self.generate(template_name, target_name, configuration)
    template_text = File.read("#{TEMPLATE_DIR}/#{template_name}")
    template = ERB.new(template_text)
    result = template.result(configuration.internal_binding)
    File.open(target_name, 'w') do |file|
      file.write(result)
    end
  end
end

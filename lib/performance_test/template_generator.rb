# frozen_string_literal: true

require 'erb'

# Class allows to generate template for the MDBCI
class TemplateGenerator
  # Generate a configuration for MDBCI based on the template file.
  #
  # @param template_name [String] name of the template to use.
  # @param target_name [String] path to the file to be generated.
  # @param contex [Binding] scope to use during creation.
  def self.generate(template_name, target_name, context)
    template_text = File.read("#{PerformanceTest::TEMPLATES_DIRECTORY}/#{template_name}")
    template = ERB.new(template_text)
    result = template.result(context)
    File.open(target_name, 'w') do |file|
      file.write(result)
    end
  end
end

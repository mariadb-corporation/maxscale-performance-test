# frozen_string_literal: true

require 'erb'

# Class allows to generate template for the MDBCI
class TemplateGenerator
  # Generate a file based on the passed template and context.
  #
  # @param template_name [String] name of the template to use.
  # @param target_name [String] path to the file to be generated.
  # @param contex [Binding] scope to use during creation.
  def self.generate(template_name, target_name, context)
    text = generate_string(template_name, context)
    File.open(target_name, 'w') do |file|
      file.write(text)
    end
  end

  # Generate a template into string based on passed template and context.
  #
  # @param template_name [String] name of the template to use
  # @param context [Binding] scope to use during the template burn.
  def self.generate_string(template_name, context)
    template_text = File.read(template_name)
    template = ERB.new(template_text)
    template.result(context)
  end
end

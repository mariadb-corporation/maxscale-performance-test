# frozen_string_literal: true

require 'iniparse'

# Class provides access to the configuration of machines
class MachineConfig
  attr_reader :configs

  # @param config [String] path to the configuration file in ini format
  def initialize(config)
    document = IniParse.parse(File.read(config))
    @configs = parse_document(document)
  end

  private

  # Parse INI document into a set of machine descriptions
  def parse_document(document)
    section = document['__anonymous__']
    options = section.enum_for(:each)
    names = options.map(&:key)
                   .select { |key| key.include?('_network') }
                   .map { |key| key.sub('_network', '') }
    configs = Hash.new { |hash, key| hash[key] = {} }
    names.each do |name|
      parameters = options.select { |option| option.key.include?(name) }
      parameters.reduce(configs) do |_result, option|
        key = option.key.sub(name, '').sub('_', '')
        configs[name][key] = option.value
      end
    end
    configs
  end
end

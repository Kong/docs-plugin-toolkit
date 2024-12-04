require 'yaml'

module JSONSchema
  class MissingDescriptions
    def self.run!(schema)
      new(schema).run!
    end

    def initialize(schema)
      @schema = schema
    end

    def run!
      @schema.fetch('properties', []).map do |prop|
        key = prop.keys.first
        values = prop.values.first

        next if values.key?('description')

        values['description'] = descriptions[key] if descriptions.key?(key)
      end
    end

    private

    def properties
      @properties ||= @schema['properties']
    end

    def descriptions
      @descriptions ||= YAML.load(File.read('./config/descriptions.yaml'))
    end
  end
end

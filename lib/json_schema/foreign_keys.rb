require 'yaml'

module JSONSchema
  class ForeignKeys
    def self.run!(schema)
      new(schema).run!
    end

    def initialize(schema)
      @schema = schema
    end

    def run!
      unsupported_entities.each { |e| properties.delete(e) }
      properties.concat(supported_entities)
    end

    private

    def properties
      @properties ||= @schema['properties']
    end

    def unsupported_entities
      @unsupported_entities ||= properties.select do |prop|
        available_entities.any? { |k| prop.key?(k) }
      end
    end

    def supported_entities
      @supported_entities ||= [
        foreign_keys.except(*unsupported_entities.flat_map(&:keys))
      ]
    end

    def foreign_keys
      @foreign_keys ||= YAML.load(File.read('./config/foreign_keys.yaml'))
    end

    def available_entities
      @available_entities ||= foreign_keys.keys
    end
  end
end

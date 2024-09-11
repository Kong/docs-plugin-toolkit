require 'json'

class ConvertJsonSchema
  def self.run!(plugins:, options:)
    new(plugins:, options:).run!
  end

  def initialize(plugins:, options:)
    @plugins = plugins
    @options = options
  end

  def run!
    schemas.each_with_object([]) do |(plugin_name, schema), fields|
      next unless File.exist?(schema)

      json_schema = JSON.parse(File.read(schema))

      # TODO: Process all fields.
      # @mheap only needs config, so that's all that's implemented
      config = get_config_fields(json_schema)
      json_schema = convert_to_json_schema(config)
      json_schema =  convert_required_list(json_schema)

      # If an entity is required, but no children are required
      # it's not actually required
      json_schema = remove_object_required_optional_children(json_schema)

      # Fix any broken defaults
      json_schema = fix_broken_defaults(json_schema)

      # Write the schema to the destination
      FileUtils.mkdir_p("#{@options[:destination]}/#{plugin_name}")
      dest = File.join(@options[:destination], plugin_name, "#{@options['version']}.json")
      File.write(dest, JSON.pretty_generate(json_schema))
    end
  end

  private

  def get_config_fields(schema)
    {
      'properties' => schema['fields'].select { |f| f.key?('config') }.first
    }
  end

  def convert_to_json_schema(props)
    # Remove required if default is set
    props.delete("required") unless props["default"].nil?

    # Loop through each field
    props = props.each_with_object({}) do |(k, v), fields|
      v = convert_type(v) if k == 'type'
      k = 'properties' if k == 'fields'
      k = 'minimum' if k == 'gt'
      k = 'maximum' if k == 'lt'
      k = 'minLength' if k == 'len_min'
      k = 'maxLength' if k == 'len_max'
      k = 'items' if k == 'elements'
      k = 'pattern' if k == 'match'
      k = 'enum' if k == 'one_of'

      if (k == 'keys' || k == 'values')
        fields['additionalProperties'] = true
        next
      end

      if k == 'between'
        fields['minimum'] = v.first
        fields['maximum'] = v.last
        next
      end

      if k == 'uuid' && fields[k]
        fields['format'] = 'uuid'
      end


      # Remove unused fields
      next if [
        'entity_checks',
        'referenceable',
        'reference',
        'encrypted',
        'err',
        'unique',
        'auto',
        'match_none',
        'starts_with',
        'deprecation'
      ].include?(k)

      if k == 'type' && v == 'foreign'
        v = 'string'
      end

      if v.is_a?(Array) && v.first.is_a?(Hash)
        v = v.reduce({}, :merge)
      end

      if v.is_a?(Hash)
        v = convert_to_json_schema(v)
      end

      fields[k] = v
    end

    if props['type'] == "number" && props['enum']
      allPropsAreIntegers = props['enum'].select { |e| e.is_a?(Integer) }.length == props['enum'].length
      if allPropsAreIntegers
        props['type'] = 'integer'
      end
    end

    props
  end

  def convert_required_list(schema)

    schema['required'] = [] if !schema['required'].is_a?(Array)

    if schema['properties']

      # Fix empty schema properties that should
      # be additionalProperties = true
      if schema['properties'].is_a?(Array)
        schema['properties'] = {}
        schema['additionalProperties'] = true
      end

      schema['properties'].each do |k, v|
        if v['required']
          schema['required'].push(k)
        end

        # Always remove required as "required: false" is invalid too
        v.delete('required')

        if v['properties']
          v = convert_required_list(v)
        end

        if v['items']
          v['items'] = convert_required_list(v['items'])
        end
      end

    end
    

    schema
  end

  def remove_object_required_optional_children(schema)
    if schema['required'] && schema['properties']
      unused = []
      schema['required'].each do |k|
        schema['properties'][k] = remove_object_required_optional_children(schema['properties'][k])
        if !schema['properties'][k]['required'] || schema['properties'][k]['required'].size == 0
          unused.push(k)
        end
      end

      schema['required'] -= unused
    end
    schema
  end

  def fix_regex(schema)
    if schema['pattern']
       # Convert Lua pattern to regex
       lua_patterns = {
        '%a' => '[a-zA-Z]',
        '%c' => '[\x00-\x1F]', # Control characters, cannot be replaced with actual characters
        '%d' => '[0-9]',
        '%g' => '[\x21-\x7E]', # Printable characters, cannot be replaced with actual characters
        '%l' => '[a-z]',
        '%p' => '[!-/:-@[-`{-~]', # Punctuation characters
        '%s' => '[\t\n\v\f\r ]', # Whitespace characters
        '%u' => '[A-Z]',
        '%w' => '[a-zA-Z0-9]',
        '%x' => '[0-9a-fA-F]'
      }

      negative_patterns = {}
      lua_patterns.each do |lua_pattern, regex|
        negative_patterns["[^"+lua_pattern+"]"] = "[^#{regex[1..-2]}]"
      end

      lua_patterns = negative_patterns.merge(lua_patterns)

      lua_patterns.each do |lua_pattern, regex|
        schema['pattern'] = schema['pattern'].gsub(lua_pattern, regex)
      end

      # Escape forward slashes
      schema['pattern'] = schema['pattern'].gsub('%/', '\\/')
    end
    if schema['items']
      schema['items'] = fix_regex(schema['items'])
    end

    return schema
  end

  def fix_broken_defaults(schema)
    if schema['default'] && schema['type'] == 'object' && schema['default'].is_a?(Array)
      schema.delete('default')
    end

    if schema['default'] && schema['type'] == 'array' && schema['default'].is_a?(Hash)
      schema['default'] = [schema['default']]
    end

    if schema['properties']
      schema['properties'].each do |k, v|
        schema['properties'][k] = fix_broken_defaults(v)
        schema['properties'][k] = fix_regex(v)
      end
    end

    return schema
  end


  def convert_type(type)
    case type
    when 'record'
      'object'
    when 'map'
      'object'
    when 'set'
      'array'
    else
      type
    end
  end

  def schemas
    @schemas ||= @plugins.map do |plugin_name|
      [plugin_name, schema_path(plugin_name)]
    end
  end

  def schema_path(plugin)
    File.join(@options['source'], plugin, "#{@options['version']}.json")
  end
end

require 'yaml'
require 'json'
require_relative 'action'

class ExampleValidator < Action
  VALID_MESSAGE = 'schema validation successful'.freeze
  REPLACEMENTS = {
    '<AWS_REGION>' => 'us-west-2',
  }

  def prerequisites; end

  def make_request!
    @res = @client.validate_plugin(request_body)
  end

  def process_response
    @response = JSON.parse(@res.body)
    @result = @response['message'] == VALID_MESSAGE
  end

  def log_result
    if @options[:verbose]
      puts '-' * 33
      puts "| Plugin: #{@plugin}"
      puts "| Source: #{file_path}"
      puts "| Response Code: #{@res.code}"
      puts "| Valid?: #{@result ? '✅' : '❌'}"
      unless @result
        @response.each { |k,v|  puts "| #{k}: #{v}" }
      end
      puts '-' * 33
    else
      puts "#{@plugin}: #{@result ? '✅' : '❌'}"
      puts @response
    end
  end

  private

  def request_body
    @request_body = begin
                      body = YAML.load(File.read(file_path)).to_json
                      REPLACEMENTS.each do |k ,v|
                        body = body.gsub("#{k}", v)
                      end

                      body
                    end
  end

  def file_path
    File.join(@options[:source], @plugin, "_#{@options[:version]}.yaml")
  end
end

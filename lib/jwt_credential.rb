require 'json'
require 'fileutils'
require_relative 'api/client'

class JWTCredential
  def self.run!(options:)
    new(options:).run!
  end

  def initialize(options:)
    @options = options
    @client  = API::Client.new(host: @options[:host], port: @options[:port])
  end

  def run!
    create_folder

    @res = @client.jwt_credential_schema

    process_response
  end

  private

  def process_response
    if success?
      @response = JSON.parse(@res.body)

      if @options['verbose']
        puts 'JWT Credential schema'
        puts JSON.pretty_generate(@response)
      else
        puts "#{success? ? '✅' : '❌'}"
      end

      write_to_file(@response)
    end
  end

  def success?
    @res && @res.code == '200'
  end

  def create_folder
    FileUtils.mkdir_p("#{@options[:destination]}/jwt_credential")
  end

  def write_to_file(jwt_credential)
    File.write(file_path, JSON.pretty_generate(jwt_credential))
  end

  def file_path
    "#{@options[:destination]}/jwt_credential/#{@options[:version]}.json"
  end
end

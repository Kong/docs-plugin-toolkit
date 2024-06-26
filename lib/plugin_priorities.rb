require 'json'
require 'fileutils'
require_relative 'api/client'

class PluginPriorities
  def self.run!(options:)
    new(options:).run!
  end

  def initialize(options:)
    @options = options
    @client  = API::Client.new(host: @options[:host], port: @options[:port])
  end

  def run!
    create_folders

    @res = @client.root

    process_response
  end

  private

  def process_response
    if success?
      @response = JSON.parse(@res.body)

      if @options['verbose']
        puts 'Plugins ordered by priority'
        puts JSON.pretty_generate(priorities)
      else
        puts "#{success? ? '✅' : '❌'}"
      end

      write_to_file(priorities)
    end
  end

  def success?
    @res && @res.code == '200'
  end

  def priorities
    @priorities ||= @response
      .dig('plugins', 'available_on_server')
      .each_with_object({}) do |(k, v), hash|
        next if k == 'konnect-application-auth'

        hash[k] = v['priority']
      end
        .sort_by { |k, v| [-v, k] }
        .to_h
  end

  def write_to_file(priorities)
    File.write(file_path, JSON.pretty_generate(priorities))
  end

  def file_path
    "#{@options[:destination]}/priorities/#{@options[:type]}/#{@options[:version]}.json"
  end

  def create_folders
    FileUtils.mkdir_p("#{@options[:destination]}/priorities/ee")
    FileUtils.mkdir_p("#{@options[:destination]}/priorities/oss")
  end
end

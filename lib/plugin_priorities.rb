require 'json'
require 'fileutils'
require_relative 'api/client'

class PluginPriorities
  def self.run!(plugins:, options:)
    new(plugins:, options:).run!
  end

  def initialize(plugins:, options:)
    @plugins = plugins
    @options = options
    @priorities = {}
  end

  def run!
    create_folders
    fetch_priorities
    order_priorities
    process_priorities
  end

  private

  def fetch_priorities
    @plugins.each do |plugin|
      handler = handler_file_path(plugin)
      next unless handler

      priority = File.read(handler)[/PRIORITY\s=\s(\d+)(,|\s*\n)/, 1].to_i
      @priorities[plugin] = priority
    end
  end

  def process_priorities
    if @options['verbose']
      puts 'Plugins ordered by priority'
      puts JSON.pretty_generate(@priorities)
    end

    write_to_file(@priorities)
  end

  def order_priorities
    @priorities = @priorities
      .select { |k, v| !v.nil? }
      .sort_by { |k, v| -v }
      .to_h
  end

  def write_to_file(priorities)
    File.write(file_path, JSON.pretty_generate(priorities))
  end

  def file_path
    "#{@options[:destination]}/priorities/#{@options[:type]}/#{@options[:version]}.json"
  end

  def create_folders
    FileUtils.mkdir_p("#{@options[:destination]}/priorities/ee/")
    FileUtils.mkdir_p("#{@options[:destination]}/priorities/oss/")
  end

  def handler_file_path(plugin)
    path = if @options[:type] == 'oss'
             "#{@options[:source]}/kong/plugins/#{plugin}/handler.lua"
           else
             ee = "#{@options[:source]}/plugins-ee/#{plugin}/kong/plugins/#{plugin}/handler.lua"
             File.exist?(ee) ? ee : "#{@options[:source]}/kong/plugins/#{plugin}/handler.lua"
           end
    if File.exist?(path)
      path
    else
      puts "Plugin #{plugin} handler.lua can't be found"
    end
  end
end

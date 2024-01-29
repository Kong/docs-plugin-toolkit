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
    create_folder
    fetch_priorities
    order_priorities
    process_priorities
  end

  private

  def fetch_priorities
    @plugins.each do |plugin|
      handler = handler_file_path(plugin)
      next unless handler

      priority = File.read(handler)[/PRIORITY\s=\s(\d+)/, 1].to_i
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
    "#{@options[:destination]}/priorities/#{@options[:version]}.json"
  end

  def create_folder
    FileUtils.mkdir_p("#{@options[:destination]}/priorities/")
  end

  def handler_file_path(plugin)
    oss_path = "#{@options[:ee_path]}/kong/plugins/#{plugin}/handler.lua"
    ee_path = "#{@options[:ee_path]}/plugins-ee/#{plugin}/kong/plugins/#{plugin}/handler.lua"
    if File.exist?(oss_path)
      oss_path
    elsif File.exist?(ee_path)
      ee_path
    else
      puts "Plugin #{plugin} handler.lua can't be found"
    end
  end
end

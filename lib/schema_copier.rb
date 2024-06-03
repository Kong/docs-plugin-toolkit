require 'fileutils'

class SchemaCopier
  def self.run!(plugin:, options:)
    new(plugin:, options:).run!
  end

  def initialize(plugin:, options:)
    @plugin  = plugin
    @options = options
  end

  def run!
    unless File.exist?("#{@options['source']}/#{@plugin}")
      puts "#{@options['source']}/#{@plugin} does not exist"
      return
    end
    if latest_example.nil? || !File.exist?(latest_example)
      puts "Latest schema for #{@plugin} does not exist"
      return
    end

    FileUtils.cp(latest_example, new_path)
  end

  private

  def latest_example
    @latest_example ||= Dir["#{@options['source']}/#{@plugin}/*.json"].sort.last
  end

  def new_path
    [@options['source'], @plugin, "#{@options[:version]}.json"].join('/')
  end
end

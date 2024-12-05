require 'fileutils'

class DataCopier
  def self.run!(options:)
    new(options:).run!
  end

  def initialize(options:)
    @options = options
  end

  def run!
    folders = Dir.glob("#{@options['source']}/**/*").select do |path|
      File.directory?(path) && Dir.glob("#{path}/*").none? { |sub| File.directory?(sub) }
    end

    folders.each do |folder|
      latest = find_latest(folder)
      FileUtils.cp(latest, new_path(folder))
    end
  end

  private

  def find_latest(folder)
    Dir["#{folder}/*.json"].sort.last
  end

  def new_path(folder)
    [folder, "#{@options[:version]}.json"].join('/')
  end
end

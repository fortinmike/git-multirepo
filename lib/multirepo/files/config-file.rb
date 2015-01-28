require "fileutils"
require "pathname"

require_relative "config-entry"

module MultiRepo
  class ConfigFile
    FILE = Pathname.new(".multirepo")
    
    def self.exists?
      FILE.exist?
    end
    
    def self.create
      template_path = Utils.path_for_resource(".multirepo")
      FileUtils.cp(template_path, ".")
    end
    
    def self.load_entries
      entries = Array.new
      
      FILE.open("r").each_line do |line|
        next if line.start_with?("#") # Barebones comments support
        next if line.strip == "" # Skip empty lines
        components = line.split(",").map(&:strip)
        validate_components(line, components)
        entries.push(ConfigEntry.new(*components))
      end
      
      return entries
    end
    
    def self.entry_exists?(entry)
      load_entries.any? { |e| Pathname.new(e.path).realpath == Pathname.new(entry.path).realpath }
    end
    
    def self.add_entry(entry)
      ConfigFile::FILE.open("a") { |f| f.puts entry.to_s }
    end

    def self.stage
      Git.run("add -A -f #{FILE.to_s}", false)
    end

    def self.validate_components(line, components)
      unless components.count == 4
        raise "Wrong entry format in .multirepo file"
      end
    end
  end
end
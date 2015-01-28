require "fileutils"
require "pathname"

require_relative "config-entry"

module MultiRepo
  class ConfigFile
    FILE = Pathname.new(".multirepo")
    
    def self.exists?
      FILE.exist?
    end
    
    def self.load
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
    
    def self.save(entries)
      # Copy template .multirepo file from resources
      template_path = Utils.path_for_resource(".multirepo")
      FileUtils.cp(template_path, ".")
      
      # Append the entries to it
      FILE.open("a") do |f|
        entries.each { |e| f.puts e.to_s }
      end
    end
    
    def self.entry_exists?(entry)
      load.any? { |e| e == entry }
    end
    
    def self.add_entry(entry)
      save(load.push(entry))
    end
    
    def self.remove_entry(entry)
      save(load.delete_if { |e| e == entry })
    end

    def self.stage
      Git.run("add -A -f #{FILE.to_s}", false)
    end

    def self.validate_components(line, components)
      unless components.count == 4
        raise MultiRepoException, "Wrong entry format in .multirepo file. Can't load entries."
      end
    end
  end
end
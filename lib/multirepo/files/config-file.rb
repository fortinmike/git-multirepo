require "fileutils"
require "pathname"

require_relative "config-entry"

module MultiRepo
  class ConfigFile
    FILE = Pathname.new(".multirepo")
    FILE_NAME = FILE.to_s
    
    def self.exists?
      FILE.exist?
    end
    
    def self.load_entries
      Psych.load(FILE.read)
    end
    
    def self.save(entries)
      File.write(FILE_NAME, Psych.dump(entries))
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
  end
end
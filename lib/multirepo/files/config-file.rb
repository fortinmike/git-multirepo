require "fileutils"
require "pathname"

require_relative "config-entry"

module MultiRepo
  class ConfigFile
    FILE = Pathname.new(".multirepo")
    FILENAME = FILE.to_s
    
    def self.exists?
      FILE.exist?
    end
    
    def self.load_entries
      Psych.load(FILE.read)
    end
    
    def self.save_entries(entries)
      File.write(FILENAME, Psych.dump(entries))
    end
    
    def self.entry_exists?(entry)
      load_entries.any? { |e| e == entry }
    end
    
    def self.add_entry(entry)
      save_entries(load_entries.push(entry))
    end
    
    def self.remove_entry(entry)
      save_entries(load_entries.delete_if { |e| e == entry })
    end
  end
end
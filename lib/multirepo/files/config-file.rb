require "fileutils"
require "pathname"

require_relative "config-entry"

module MultiRepo
  class ConfigFile
    FILENAME = ".multirepo"
    
    def initialize(path)
      @path = path
    end
    
    def file
      File.join(@path, FILENAME)
    end
    
    def filename
      FILENAME
    end
    
    def exists?
      File.exist?(file)
    end
    
    def load_entries
      fail MultiRepoException, "Can't read config file (no permission)" if !File.stat(file).readable?
      Psych.load(File.read(file))
    end
    
    def save_entries(entries)
      fail MultiRepoException, "Can't write config file (no permission)" if !File.stat(file).writable?
      File.write(file, Psych.dump(entries))
    end
    
    def entry_exists?(entry)
      load_entries.any? { |e| e == entry }
    end
    
    def add_entry(entry)
      save_entries(load_entries.push(entry))
    end
    
    def remove_entry(entry)
      save_entries(load_entries.delete_if { |e| e == entry })
    end
  end
end

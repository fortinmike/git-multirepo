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
      ensure_access(file, "Can't read config file (permissions)") { |stat| stat.readable? }
      Psych.load(File.read(file))
    end
    
    def save_entries(entries)
      ensure_access(file, "Can't write config file (permissions)") { |stat| stat.writable? }
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

    def ensure_access(file, error_message, &check)
      fail MultiRepoException, error_message if File.exists?(file) && !check.call(File.stat(file))
    end
  end
end

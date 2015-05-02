require "pathname"
require "psych"

require "multirepo/git/git"
require_relative "lock-entry"
require_relative "config-file"

module MultiRepo
  class LockFile
    FILE = Pathname.new(".multirepo.lock")
    FILE_NAME = FILE.to_s
    
    def self.exists?
      FILE.exist?
    end
    
    def self.load_entries
      Psych.load(FILE.read)
    end
    
    def self.update
      config_entries = ConfigFile.load_entries
      lock_entries = config_entries.map { |c| LockEntry.new(c) }
      
      old_content = File.read(FILE_NAME)
      new_content = Psych.dump(lock_entries)
      File.write(FILE_NAME, new_content)
      
      return new_content != old_content
    end
  end
end
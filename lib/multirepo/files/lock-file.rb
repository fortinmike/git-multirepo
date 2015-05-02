require "pathname"
require "psych"

require "multirepo/git/git"
require_relative "tracking-file"
require_relative "lock-entry"
require_relative "config-file"

module MultiRepo
  class LockFile < TrackingFile
    FILE = Pathname.new(".multirepo.lock")
    FILENAME = FILE.to_s
    
    def self.exists?
      FILE.exist?
    end
    
    def self.load_entries
      Psych.load(FILE.read)
    end
    
    def self.update
      config_entries = ConfigFile.load_entries
      lock_entries = config_entries.map { |c| LockEntry.new(c) }
      content = Psych.dump(lock_entries)
      return update_internal(FILENAME, content)
    end
  end
end
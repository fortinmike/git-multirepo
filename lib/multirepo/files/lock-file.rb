require "pathname"
require "psych"

require "multirepo/git/git"
require_relative "lock-entry"
require_relative "config-file"

module MultiRepo
  class LockFile
    FILE = Pathname.new(".multirepo.lock")
    
    def self.exists?
      FILE.exist?
    end
    
    def self.load_entries
      return Psych.load(FILE.read)
    end
    
    def self.update
      config_entries = ConfigFile.load_entries
      lock_entries = config_entries.map { |c| LockEntry.new(c) }
      
      File.write(FILE.to_s, Psych.dump(lock_entries))
      
      Git.run("add -A -f #{FILE.to_s}", false)
    end
    
    def self.validate_components(line, components)
      unless components.count == 2
        raise MultiRepoException, "Wrong entry format in .multirepo.lock file: #{line}"
      end
    end
  end
end
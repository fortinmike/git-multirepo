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
    
    def self.stage
      Git.run_in_current_dir("add -A #{FILE_NAME}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end

    def self.commit(message)
      Git.run_in_current_dir("commit -m \"#{message}\" -o -- #{FILE_NAME}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def self.validate_components(line, components)
      unless components.count == 2
        raise MultiRepoException, "Wrong entry format in .multirepo.lock file: #{line}"
      end
    end
  end
end
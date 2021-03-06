require "pathname"
require "psych"

require_relative "tracking-file"
require_relative "lock-entry"
require_relative "config-file"

module MultiRepo
  class LockFile < TrackingFile
    FILENAME = ".multirepo.lock"
    
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
      ensure_access(file, "Can't read lock file (permissions)") { |stat| stat.readable? }
      Psych.load(File.read(file))
    end
    
    def update
      ensure_access(file, "Can't write lock file (permissions)") { |stat| stat.writable? }
      config_entries = ConfigFile.new(@path).load_entries
      lock_entries = config_entries.map { |c| LockEntry.new(c) }
      content = Psych.dump(lock_entries)
      return update_internal(file, content)
    end
    
    def validate!
      load_entries.all? { |e| validate_entry! e }
    end
    
    def validate_entry!(entry)
      valid = true
      
      # head
      valid &= /\b([a-f0-9]{40})\b/ =~ entry.head.to_s
      
      # branch
      GitRunner.run(@path, "check-ref-format --branch #{entry.branch}", Verbosity::OUTPUT_NEVER)
      valid &= (entry.branch == "" || GitRunner.last_command_succeeded)
      
      return valid
    end

    def ensure_access(file, error_message, &check)
      fail MultiRepoException, error_message if File.exists?(file) && !check.call(File.stat(file))
    end
  end
end

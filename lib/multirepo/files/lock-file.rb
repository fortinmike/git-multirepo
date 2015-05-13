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
      File.exists?(file)
    end
    
    def load_entries
      Psych.load(File.read(file))
    end
    
    def update
      config_entries = ConfigFile.new(@path).load_entries
      lock_entries = config_entries.map { |c| LockEntry.new(c) }
      content = Psych.dump(lock_entries)
      return update_internal(file, content)
    end
  end
end
require "pathname"
require "psych"

require "multirepo/info"
require_relative "tracking-file"
require_relative "lock-entry"
require_relative "config-file"

module MultiRepo
  class MetaFile < TrackingFile
    FILENAME = ".multirepo.meta"
    
    attr_accessor :version
    
    def initialize(path)
      @path = path
      @version = MultiRepo::VERSION
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
    
    def encode_with(coder)
      coder["version"] = @version
    end
        
    def load
      ensure_access(file, "Can't read meta file (permissions)") { |stat| stat.readable? }
      Psych.load(File.read(file))
    end
    
    def update
      ensure_access(file, "Can't write meta file (permissions)") { |stat| stat.writable? }
      content = Psych.dump(self)
      return update_internal(file, content)
    end

    def ensure_access(file, error_message, &check)
      fail MultiRepoException, error_message if File.exists?(file) && !check.call(File.stat(file))
    end
  end
end

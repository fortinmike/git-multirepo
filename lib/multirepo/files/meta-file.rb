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
    
    def encode_with(coder)
      coder["version"] = @version
    end
        
    def load
      fail MultiRepoException, "Can't read meta file (no permission)" if !File.stat(file).readable?
      Psych.load(File.read(file))
    end
    
    def update
      fail MultiRepoException, "Can't write meta file (no permission)" if !File.stat(file).writable?
      content = Psych.dump(self)
      return update_internal(file, content)
    end
  end
end

require "pathname"
require "psych"

require "info"
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
      Psych.load(file)
    end
    
    def update
      content = Psych.dump(self)
      return update_internal(file, content)
    end
  end
end
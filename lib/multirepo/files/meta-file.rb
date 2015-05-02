require "pathname"
require "psych"

require "info"
require "multirepo/git/git"
require_relative "tracking-file"
require_relative "lock-entry"
require_relative "config-file"

module MultiRepo
  class MetaFile < TrackingFile
    FILE = Pathname.new(".multirepo.meta")
    FILENAME = FILE.to_s
    
    attr_accessor :version
    
    def initialize
      @version = MultiRepo::VERSION
    end
    
    def encode_with(coder)
      coder["version"] = @version
    end
        
    def self.load
      Psych.load(FILE.read)
    end
    
    def self.update
      content = Psych.dump(MetaFile.new)
      return update_internal(FILENAME, content)
    end
  end
end
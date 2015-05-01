require "pathname"
require "psych"

require "multirepo/git/git"
require_relative "lock-entry"
require_relative "config-file"

module MultiRepo
  class MetaFile
    FILE = Pathname.new(".multirepo.meta")
    
    def self.load
      Psych.load(FILE.read)
    end
    
    def self.update
      content = Psych.dump(self)
      File.write(FILE.to_s, content)
    end
    
    def self.stage
      Git.run_in_current_dir("add -A #{FILE.to_s}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def self.commit(message)
      Git.run_in_current_dir("commit -m \"#{message}\" -o -- #{FILE.to_s}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
  end
end
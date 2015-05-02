require "pathname"
require "psych"

require "multirepo/git/git"
require_relative "lock-entry"
require_relative "config-file"

module MultiRepo
  class MetaFile
    FILE = Pathname.new(".multirepo.meta")
    FILE_NAME = FILE.to_s
    
    def self.load
      Psych.load(FILE.read)
    end
    
    def self.update
      content = Psych.dump(self)
      File.write(FILE_NAME, content)
    end
    
    def self.stage
      Git.run_in_current_dir("add -A #{FILE_NAME}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def self.commit(message)
      Git.run_in_current_dir("commit -m \"#{message}\" -o -- #{FILE_NAME}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
  end
end
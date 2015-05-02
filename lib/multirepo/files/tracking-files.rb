require "multirepo/git/git"
require_relative "meta-file"
require_relative "lock-file"

module MultiRepo
  class TrackingFiles
    FILE_CLASSES = [MetaFile, LockFile]
    
    def self.update
      return FILE_CLASSES.any? { |c| c.update }
    end
    
    def self.stage
      FILE_CLASSES.each do |c|
        Git.run_in_current_dir("add -A #{c::FILENAME}", Runner::Verbosity::OUTPUT_ON_ERROR)
      end
    end
    
    def self.commit(message)
      pathspec = FILE_CLASSES.map{ |c| c::FILENAME }.join(" ")
      Git.run_in_current_dir("commit -m \"#{message}\" -o -- #{pathspec}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def self.delete
      FILE_CLASSES.each { |c| FileUtils.rm_f(c::FILENAME) }
    end
  end
end
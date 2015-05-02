require "multirepo/git/git"
require_relative "meta-file"
require_relative "lock-file"

module MultiRepo
  class TrackingFiles
    @tracking_file_classes = [MetaFile, LockFile]
    
    def self.update
      return @tracking_file_classes.any? { |c| c.update }
    end
    
    def self.stage
      @tracking_file_classes.each do |c|
        Git.run_in_current_dir("add -A #{c::FILE_NAME}", Runner::Verbosity::OUTPUT_ON_ERROR)
      end
    end
    
    def self.commit(message)
      pathspec = @tracking_file_classes.map{ |c| c::FILE_NAME }.join(" ")
      Git.run_in_current_dir("commit -m \"#{message}\" -o -- #{pathspec}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def self.delete
      @tracking_file_classes.each { |c| FileUtils.rm_f(c::FILE_NAME) }
    end
  end
end
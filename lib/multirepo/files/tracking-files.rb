require "multirepo/git/git"
require_relative "meta-file"
require_relative "lock-file"

module MultiRepo
  class TrackingFiles
    FILE_CLASSES = [MetaFile, LockFile]
    
    def self.update
      updated = false
      FILE_CLASSES.each do |file_class|
        updated |= file_class.update
      end
      return updated
    end
    
    def self.stage
      Git.run_in_current_dir("add --force -- #{files_pathspec}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def self.commit(message)
      stage
      
      output = Git.run_in_current_dir("ls-files --modified --others -- #{files_pathspec}", Runner::Verbosity::NEVER_OUTPUT)
      files_are_untracked_or_modified = output.strip != ""
      
      output = Git.run_in_current_dir("diff --name-only --cached -- #{files_pathspec}", Runner::Verbosity::NEVER_OUTPUT)
      files_are_staged = output.strip != ""
      
      must_commit = files_are_untracked_or_modified || files_are_staged
      Git.run_in_current_dir("commit -m \"#{message}\" --only -- #{files_pathspec}", Runner::Verbosity::OUTPUT_ON_ERROR) if must_commit
            
      return must_commit
    end
    
    def self.delete
      FILE_CLASSES.each { |c| FileUtils.rm_f(c::FILENAME) }
    end
    
    def self.files_pathspec
      FILE_CLASSES.map{ |c| c::FILENAME }.join(" ")
    end
  end
end
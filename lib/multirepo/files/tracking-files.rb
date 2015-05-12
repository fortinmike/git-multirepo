require "multirepo/git/git-runner"
require_relative "meta-file"
require_relative "lock-file"

module MultiRepo
  class TrackingFiles
    FILES = [MetaFile.new("."), LockFile.new(".")]
    
    def self.update
      updated = false
      FILES.each { |f| updated |= f.update }
      return updated
    end
    
    def self.stage
      GitRunner.run_in_current_dir("add --force -- #{files_pathspec}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def self.commit(message)
      stage
      
      output = GitRunner.run_in_current_dir("ls-files --modified --others -- #{files_pathspec}", Runner::Verbosity::OUTPUT_NEVER)
      files_are_untracked_or_modified = output.strip != ""
      
      output = GitRunner.run_in_current_dir("diff --name-only --cached -- #{files_pathspec}", Runner::Verbosity::OUTPUT_NEVER)
      files_are_staged = output.strip != ""
      
      must_commit = files_are_untracked_or_modified || files_are_staged
      GitRunner.run_in_current_dir("commit -m \"#{message}\" --only -- #{files_pathspec}", Runner::Verbosity::OUTPUT_ON_ERROR) if must_commit
            
      return must_commit
    end
    
    def self.delete
      FILES.each { |f| FileUtils.rm_f(f.file) }
    end
    
    def self.files_pathspec
      FILES.map{ |f| f.file }.join(" ")
    end
  end
end
require "multirepo/git/git-runner"
require_relative "meta-file"
require_relative "lock-file"

module MultiRepo
  class TrackingFiles
    attr_accessor :files
    
    def initialize(path)
      @path = path
      @files = [MetaFile.new(path), LockFile.new(path)]
    end
    
    def update
      updated = false
      files.each { |f| updated |= f.update }
      return updated
    end
    
    def stage
      GitRunner.run_in_current_dir("add --force -- #{files_pathspec}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def commit(message)
      stage
      
      output = GitRunner.run_in_current_dir("ls-files --modified --others -- #{files_pathspec}", Runner::Verbosity::OUTPUT_NEVER)
      files_are_untracked_or_modified = output.strip != ""
      
      output = GitRunner.run_in_current_dir("diff --name-only --cached -- #{files_pathspec}", Runner::Verbosity::OUTPUT_NEVER)
      files_are_staged = output.strip != ""
      
      must_commit = files_are_untracked_or_modified || files_are_staged
      GitRunner.run_in_current_dir("commit -m \"#{message}\" --only -- #{files_pathspec}", Runner::Verbosity::OUTPUT_ON_ERROR) if must_commit
            
      return must_commit
    end
    
    def delete
      files.each { |f| FileUtils.rm_f(f.file) }
    end
    
    def files_pathspec
      files.map{ |f| f.file }.join(" ")
    end
  end
end
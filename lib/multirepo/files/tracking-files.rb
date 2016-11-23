require "multirepo/git/git-runner"
require_relative "meta-file"
require_relative "lock-file"
require "multirepo/info"
require "multirepo/logic/version-comparer"

module MultiRepo
  class TrackingFiles
    attr_accessor :files
    
    def initialize(path)
      @path = path
      @meta_file = MetaFile.new(path)
      @lock_file = LockFile.new(path)
      @files = [@meta_file, @lock_file]
    end
    
    def update
      ensure_tool_not_outdated
      updated = false
      files.each { |f| updated |= f.update }
      return updated
    end

    def ensure_tool_not_outdated
      # TODO: Also outdated if the tracking file does not exist 
      current_version = MultiRepo::VERSION
      meta_version = @meta_file.load.version
      outdated_tool = !VersionComparer.is_latest(current: current_version, last: meta_version)

      message = "Can't update tracking files with an outdated version of git-multirepo\n" + 
                "  Current version is #{current_version} and repo is tracked by #{meta_version}"

      fail MultiRepoException, message if outdated_tool
    end
    
    def stage
      GitRunner.run(@path, "add --force -- #{files_pathspec}", Verbosity::OUTPUT_ON_ERROR)
    end
    
    def commit(message)
      stage
      
      output = GitRunner.run(@path, "ls-files --modified --others -- #{files_pathspec}", Verbosity::OUTPUT_NEVER)
      files_are_untracked_or_modified = output.strip != ""
      
      output = GitRunner.run(@path, "diff --name-only --cached -- #{files_pathspec}", Verbosity::OUTPUT_NEVER)
      files_are_staged = output.strip != ""
      
      must_commit = files_are_untracked_or_modified || files_are_staged
      GitRunner.run(@path, "commit --no-verify -m \"#{message}\" --only -- #{files_pathspec}", Verbosity::OUTPUT_ON_ERROR) if must_commit
      
      return must_commit
    end
    
    def delete
      files.each { |f| FileUtils.rm_f(f.file) }
    end
    
    def files_pathspec
      files.map{ |f| File.basename(f.file) }.join(" ")
    end
  end
end

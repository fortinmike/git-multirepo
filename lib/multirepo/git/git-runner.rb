require "multirepo/utility/runner"
require "multirepo/config"

module MultiRepo
  class GitRunner
    class << self
      attr_accessor :last_command_succeeded
    end
    
    def self.run(path, git_command, verbosity)
      if path == "."
        # It is always better to skip -C when running git commands in the
        # current directory (especially in hooks). Doing this prevents
        # any future issues because we automatically fallback to non-"-C" for ".".
        # Fixes bug: https://www.pivotaltracker.com/story/show/94505654
        return run_internal("#{git_executable} #{git_command}", verbosity)
      end
      
      full_command = "#{git_executable} -C \"#{path}\" #{git_command}";
      if Config.instance.running_git_hook
        # True fix for the -C flag issue in pre-commit hook where the status command would
        # fail to provide correct results if a pathspec was provided when performing a commit.
        # http://thread.gmane.org/gmane.comp.version-control.git/263319/focus=263323
        full_command = "sh -c 'unset $(git rev-parse --local-env-vars); #{full_command};'" 
      end
      
      run_internal(full_command, verbosity)
    end
    
    private
    
    def self.run_internal(full_command, verbosity)
      result = Runner.run(full_command, verbosity)
      @last_command_succeeded = Runner.last_command_succeeded
      return result
    end

    def self.git_executable
      Config.instance.git_executable || "git"
    end
  end
end
require "multirepo/utility/runner"
require "multirepo/git/git"
require "multirepo/config"

module MultiRepo
  class Git
    class << self
      attr_accessor :last_command_succeeded
    end
    
    def self.run_in_current_dir(git_command, show_output)
      full_command = "git #{git_command}"
      run(full_command, show_output)
    end
    
    def self.run_in_working_dir(path, git_command, show_output)
      full_command = "git -C \"#{path}\" #{git_command}";
      
      # True fix for the -C flag issue in pre-commit hook where the status command would
      # fail to provide correct results if a pathspec was provided when performing a commit.
      # http://thread.gmane.org/gmane.comp.version-control.git/263319/focus=263323
      full_command = "sh -c 'unset $(git rev-parse --local-env-vars); #{full_command};'" if Config.instance.running_git_hook
      
      run(full_command, show_output)
    end
    
    def self.run(full_command, show_output)
      Console.log_info(full_command) if Config.instance.verbose
      result = Runner.run(full_command, show_output)
      @last_command_succeeded = Runner.last_command_succeeded
      return result
    end
    
    def self.is_inside_git_repo(path)
      return false unless Dir.exist?("#{path}/.git")
      return Git.run_in_working_dir(path, "rev-parse --is-inside-work-tree", false).strip == "true"
    end
  end
end
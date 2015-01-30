require "multirepo/utility/runner"
require "multirepo/git/git"
require "multirepo/config"

module MultiRepo
  class Git
    def self.run_in_current_dir(git_command, show_output)
      full_command = "git #{git_command}"
      Console.log_info(full_command) if Config.instance.verbose
      Runner.run(full_command, show_output)
    end
    
    def self.run_in_working_dir(path, git_command, show_output)
      # http://stackoverflow.com/a/1387631/167983
      
      full_command = "git -C \"#{path}\" #{git_command}";
      Console.log_info(full_command) if Config.instance.verbose
      Runner.run(full_command, show_output)
    end
    
    def self.is_inside_git_repo(path)
      Dir.exist?("#{path}/.git")
      #return (Git.run_in_working_dir(path, "rev-parse --is-inside-work-tree", false).strip == "true") # Can't silence output?
    end
  end
end
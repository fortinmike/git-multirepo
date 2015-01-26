require "multirepo/utility/runner"
require "multirepo/git/git"

module MultiRepo
  class Git
    def self.run(*args)
      # No method overloading makes me sad
      if args.length == 2
        self.run_in_current_dir(*args)
      elsif args.length == 3
        self.run_in_working_dir(*args)
      else
        raise "Wrong number of arguments in Git.run() call"
      end
    end
    
    def self.run_in_current_dir(git_command, show_output)
      full_command = "git #{git_command}"
      Console.log_info(full_command)
      Runner.run(full_command, show_output)
    end
    
    def self.run_in_working_dir(working_copy, git_command, show_output)
      # Run command in subshell for this to work when called from a script
      # http://stackoverflow.com/a/1387631/167983
      
      full_command = "(cd #{working_copy} && git #{git_command})";
      Console.log_info(full_command)
      Runner.run(full_command, show_output)
    end
    
    def self.is_inside_git_repo(working_copy)
      Dir.exist?("#{working_copy}/.git")
      #return (Git.run(working_copy, "rev-parse --is-inside-work-tree", false).strip == "true") # Can't silence output?
    end
  end
end
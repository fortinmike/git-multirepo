require_relative "runner"

module MultiRepo
  class Git
    def self.run(*args)
      # No method overloading makes me sad
      if args.length == 2
        self.run_in_current_dir(*args)
      elsif args.length == 3
        self.run_in_working_dir(*args)
      else
        raise
      end
    end
    
    def self.run_in_current_dir(command, show_output)
      full_command = "git #{command}"
      MultiRepo::Runner.run(full_command, show_output)
    end
    
    def self.run_in_working_dir(working_dir, command, show_output)
      full_command = "git --git-dir=\"#{working_dir}/.git\" --work-tree=\"#{working_dir}\" #{command}";
      MultiRepo::Runner.run(full_command, show_output)
    end
  end
end
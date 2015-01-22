require_relative "console"
require_relative "git"
require_relative "branch"

module MultiRepo
  class Repo
    attr_accessor :folder_name
    attr_accessor :remote_url
    
    attr_accessor :working_copy
    attr_accessor :branch
    
    def initialize(folder_name, remote_url, branch_name)
      @folder_name = folder_name
      @remote_url = remote_url
      
      @working_copy = "../#{folder_name}"
      @branch = Branch.new(self, branch_name)
    end
    
    def exists?
      Dir.exist?("#{@working_copy}/.git")
    end
    
    def setup
      # Fetch or clone the remote
      if exists?
        # TODO: Check if the existing repo's origin matches the expected remote
        Console.log_substep("Working copy #{@working_copy} already exists, fetching instead...")
        if !fetch then
          Console.log_error("Could not fetch from remote #{@remote_url}")
          return
        end
      else
        Console.log_substep("Cloning #{@remote_url} to #{@working_copy}")
        if !clone then
          Console.log_error("Could not clone remote #{@remote_url}")
          return
        end
      end
      
      # Create and switch to the appropriate branch
      @branch.create unless @branch.exists?  
      if @branch.checkout
        Console.log_info("Checked out branch #{branch.name}")
      else
        Console.log_error("Could not checkout branch #{branch.name}")
      end
    end
    
    # General
    
    def fetch
      Git.run(@working_copy, "fetch", true)
      return $?.exitstatus == 0
    end
    
    def clone
      Git.run("clone #{@remote_url} #{@working_copy}", true)
      return $?.exitstatus == 0
    end
  end
end
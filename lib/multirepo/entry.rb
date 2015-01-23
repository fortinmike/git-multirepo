require_relative "console"
require_relative "git"
require_relative "branch"
require_relative "repo"

module MultiRepo
  class Entry
    attr_accessor :folder_name
    attr_accessor :remote_url
    attr_accessor :branch
    
    def initialize(folder_name, remote_url, branch_name)
      @repo = Repo.new("../#{folder_name}")
      @remote_url = remote_url
      @branch_name = branch_name
    end
    
    def install
      clone_or_fetch
      checkout_branch
    end
    
    def clone_or_fetch
      if @repo.exists?
        # TODO: Check if the existing repo's origin matches the expected remote
        Console.log_substep("Working copy #{@working_copy} already exists, fetching instead...")
        if !@repo.fetch then
          Console.log_error("Could not fetch from remote #{@remote_url}")
          return
        end
      else
        Console.log_substep("Cloning #{@remote_url} to #{@working_copy}")
        if !@repo.clone(@remote_url) then
          Console.log_error("Could not clone remote #{@remote_url}")
          return
        end
      end
    end
    
    def checkout_branch
      branch = @repo.branch(@branch_name);
      
      unless branch.exists?
        if branch.create then Console.log_info("Created branch #{branch.name}") end
      end
      
      if branch.checkout
        Console.log_info("Checked out branch #{branch.name}")
      else
        Console.log_error("Could not checkout branch #{branch.name}")
      end
    end
  end
end
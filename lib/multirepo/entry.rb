require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class Entry
    def initialize(folder_name, remote_url, branch_name)
      @repo = Repo.new("../#{folder_name}")
      @remote_url = remote_url
      @branch_name = branch_name
    end
    
    def install
      checkout_branch if clone_or_fetch
    end
    
    def clone_or_fetch
      if @repo.exists?
        unless remote_matches_entry
          puts Console.log_error("Remote does not match for working copy #{@repo.working_copy}!")
          return false
        end
        
        Console.log_substep("Working copy #{@repo.working_copy} already exists, fetching instead...")
        if !@repo.fetch then
          Console.log_error("Could not fetch from remote #{@repo.remote('origin').url}")
          return false
        end
      else
        Console.log_substep("Cloning #{@remote_url} to #{@repo.working_copy}")
        if !@repo.clone(@remote_url) then
          Console.log_error("Could not clone remote #{@remote_url}")
          return false
        end
      end
      
      true
    end
    
    def checkout_branch
      branch = @repo.branch(@branch_name);
      
      if !branch.exists? && branch.create(remote_tracking: true)
        Console.log_info("Created branch #{branch.name}")
      end
      
      if branch.checkout
        Console.log_info("Checked out branch #{branch.name} -> origin/#{branch.name}")
      else
        Console.log_error("Could not setup branch #{branch.name}")
        return false
      end
      
      true
    end
    
    def remote_matches_entry
      @repo.remote("origin").url == @remote_url
    end
  end
end
require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"

module MultiRepo
  class Setup < Command
    self.command = "install"
    self.summary = "Clones and checks out dependencies as defined in the .multirepo file, and installs git-multirepo's local pre-commit hook."
    
    def run
      super
      ensure_multirepo_initialized
      
      Console.log_step("Cloning dependencies and installing hook...")
      
      ConfigFile.load.each { |e| install(e) }
      
      self.install_pre_commit_hook
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def install(entry)
      if entry.repo.exists?
        check_repo_validity(entry)
        fetch_repo(entry)
      else
        clone_repo(entry)
      end
      checkout_branch(entry)
    end
    
    # Repo operations
    
    def fetch_repo(entry)
      Console.log_substep("Working copy #{entry.repo.path} already exists, fetching instead...")
      if !entry.repo.fetch then raise MultiRepoException, "Could not fetch from remote #{entry.repo.remote('origin').url}"
      end
    end
    
    def clone_repo(entry)
      Console.log_substep("Cloning #{entry.remote_url} to #{entry.repo.path}")
      if !entry.repo.clone(entry.remote_url) then raise MultiRepoException, "Could not clone remote #{entry.remote_url}" end
    end
    
    def checkout_branch(entry)
      branch = entry.repo.branch(entry.branch);
      
      if branch.checkout
        Console.log_substep("Checked out branch #{branch.name} -> origin/#{branch.name}")
      else
        raise MultiRepoException, "Could not checkout branch #{branch.name}"
      end
    end
    
    # Validation
    
    def check_repo_validity(entry)
      unless entry.repo.remote("origin").url == entry.remote_url
        raise MultiRepoException, "#{entry.path} origin URL (#{entry.repo.remote('origin').url}) does not match entry (#{entry.remote_url})!"
      end
    end
  end
end
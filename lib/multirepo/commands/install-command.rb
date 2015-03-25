require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"

module MultiRepo
  class InstallCommand < Command
    self.command = "install"
    self.summary = "Clones and checks out dependencies as defined in the .multirepo file, and installs git-multirepo's local pre-commit hook."
    
    def run
      validate_in_work_tree
      ensure_multirepo_initialized
      
      Console.log_step("Cloning dependencies and installing hook...")
      
      install_internal
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def install_internal
      config_entries = ConfigFile.load

      Console.log_info("There are #{config_entries.count} dependencies to install");
      
      config_entries.each { |e| install(e) }
      
      install_pre_commit_hook
    end
    
    def install(entry)
      if entry.repo.exists?
        check_repo_validity(entry)
        fetch_repo(entry)
      else
        clone_repo(entry)
      end

      # Install the pre-commit hook in the dependency repo if it is itself tracked with multirepo
      entry_config_path = File.join(entry.repo.path, ".multirepo")
      install_pre_commit_hook(entry.repo.path) if File.exists?(entry_config_path)

      checkout_branch(entry)
    end
    
    # Repo operations
    
    def fetch_repo(entry)
      Console.log_substep("Working copy '#{entry.repo.path}' already exists, fetching instead...")
      raise MultiRepoException, "Could not fetch from remote #{entry.repo.remote('origin').url}" unless entry.repo.fetch
    end
    
    def clone_repo(entry)
      Console.log_substep("Cloning '#{entry.url} to #{entry.repo.path}'")
      raise MultiRepoException, "Could not clone remote #{entry.url}" unless entry.repo.clone(entry.url)
    end
    
    def checkout_branch(entry)
      branch = entry.repo.branch(entry.branch);
      raise MultiRepoException, "Could not checkout branch #{branch.name}" unless branch.checkout
      Console.log_substep("Checked out branch #{branch.name} -> origin/#{branch.name}")
    end
    
    # Validation
    
    def check_repo_validity(entry)
      unless entry.repo.remote("origin").url == entry.url
        raise MultiRepoException, "'#{entry.path}' origin URL (#{entry.repo.remote('origin').url}) does not match entry (#{entry.url})!"
      end
    end
  end
end
require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"
require "multirepo/commands/checkout-command"

module MultiRepo
  class InstallCommand < Command
    self.command = "install"
    self.summary = "Clones and checks out dependencies as defined in the version-controlled multirepo metadata files and installs git-multirepo's local hooks."
    
    def self.options
      [['[ref]', 'The branch, tag or commit id to checkout. Checkout will use "master" if unspecified.']].concat(super)
    end
    
    def initialize(argv)
      @ref = argv.shift_argument
      super
    end
        
    def run
      validate_in_work_tree
      ensure_multirepo_initialized
      
      Console.log_step("Cloning dependencies and installing hook...")
      
      install_core(@ref)
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def install_core(ref)
      config_entries = ConfigFile.load

      Console.log_substep("Installing #{config_entries.count} dependencies...");
      
      # Clone or fetch configured repos
      config_entries.each { |e| clone_or_fetch(e) }
      
      # Checkout the repos as specified in the lock file
      checkout_command = CheckoutCommand.new(CLAide::ARGV.new([]))
      checkout_command.checkout_core(ref || "master", CheckoutCommand::CheckoutMode::LATEST)
      
      install_hooks
    end
    
    def clone_or_fetch(entry)
      if entry.repo.exists?
        check_repo_validity(entry)
        fetch_repo(entry)
      else
        clone_repo(entry)
      end
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
require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"
require "multirepo/commands/checkout-command"

module MultiRepo
  class InstallCommand < Command
    self.command = "install"
    self.summary = "Clones and checks out dependencies as defined in the version-controlled multirepo metadata files and installs git-multirepo's local git hooks."
    
    def self.options
      [
        ['-hooks', 'Only install local git hooks.'],
        ['[ref]', 'The branch, tag or commit id to checkout. Checkout will use "master" if unspecified.']
      ].concat(super)
    end
    
    def initialize(argv)
      @hooks = argv.flag?("hooks")
      @ref = argv.shift_argument
      super
    end
        
    def run
      validate_in_work_tree
      ensure_multirepo_initialized
      
      if @hooks
        Console.log_step("Installing hooks in main repo and all dependencies...")
        install_hooks_step
      else
        Console.log_step("Cloning dependencies and installing hooks...")
        install_dependencies_step(@ref)
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def install_dependencies_step(ref)
      config_entries = ConfigFile.load
      
      Console.log_substep("Installing #{config_entries.count} dependencies...");
      
      # Clone or fetch all configured dependencies
      config_entries.each { |entry| clone_or_fetch(entry) }
      
      # Checkout the appropriate branches as specified in the lock file
      checkout_command = CheckoutCommand.new(CLAide::ARGV.new([]))
      checkout_command.checkout_step(ref || "master", CheckoutCommand::CheckoutMode::LATEST)
      
      install_hooks_step
    end
    
    def install_hooks_step
      install_hooks
      Console.log_substep("Installed git hooks in main repo")
      
      install_hooks_in_multirepo_enabled_dependencies
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
      Console.log_substep("Cloning #{entry.url} into '#{entry.repo.path}'")
      raise MultiRepoException, "Could not clone remote #{entry.url}" unless entry.repo.clone(entry.url)
    end
    
    # Validation
    
    def check_repo_validity(entry)
      unless entry.repo.remote("origin").url == entry.url
        raise MultiRepoException, "'#{entry.path}' origin URL (#{entry.repo.remote('origin').url}) does not match entry (#{entry.url})!"
      end
    end
  end
end
require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"
require "multirepo/commands/checkout-command"

module MultiRepo
  class InstallCommand < Command
    self.command = "install"
    self.summary = "Clones and checks out dependencies as defined in the version-controlled multirepo metadata files and installs git-multirepo's local git hooks."
    
    def self.options
      [['[--hooks]', 'Only install local git hooks.']].concat(super)
    end
    
    def initialize(argv)
      @hooks = argv.flag?("hooks")
      super
    end
        
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_tracked
      
      if @hooks
        Console.log_step("Installing hooks in main repo and all dependencies...")
        install_hooks_step
      else
        Console.log_step("Cloning dependencies and installing hooks...")
        full_install
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def full_install
      install_dependencies_step
      install_hooks_step
      update_gitconfigs_step
    end
    
    def install_dependencies_step
      # Read config entries as-is on disk, without prior checkout
      config_entries = ConfigFile.load_entries
      Console.log_substep("Installing #{config_entries.count} dependencies...");
      
      # Clone or fetch all configured dependencies to make sure nothing is missing locally
      config_entries.each { |entry| clone_or_fetch(entry) }
      
      # Checkout the appropriate branches as specified in the lock file
      checkout_command = CheckoutCommand.new(CLAide::ARGV.new([]))
      checkout_command.dependencies_checkout_step(CheckoutCommand::CheckoutMode::LATEST)
    end
    
    def install_hooks_step
      install_hooks(".")
      Console.log_substep("Installed git hooks in main repo")
      
      multirepo_enabled_dependencies.each do |entry|
        install_hooks(entry.repo.path)
        Console.log_substep("Installed hooks in multirepo-enabled dependency '#{entry.repo.path}'")
      end
    end
    
    def update_gitconfigs_step
      update_gitconfig(".")
      Console.log_substep("Updated .git/config file")
      
      multirepo_enabled_dependencies.each do |entry|
        update_gitconfig(entry.repo.path)
        Console.log_substep("Updated .git/config in multirepo-enabled dependency '#{entry.repo.path}'")
      end
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
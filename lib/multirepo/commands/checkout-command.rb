require "multirepo/utility/console"

module MultiRepo
  class CheckoutCommand < Command
    self.command = "checkout"
    self.summary = "Checks out the specified commit or branch of the main repo and checks out matching versions of all dependencies."
    
    class CheckoutMode
      AS_LOCK = 0
      LATEST = 1
      EXACT = 2
    end
    
    def self.options
      [
        ['[ref]', 'The main repo tag, branch or commit id to checkout.'],
        ['--latest', 'Checkout the HEAD of each dependency branch (as recorded in the lock file) instead of the exact required commits.'],
        ['--exact', 'Checkout the exact specified ref for each repo, regardless of what\'s stored in the lock file.']
      ].concat(super)
    end
    
    def initialize(argv)
      @ref = argv.shift_argument
      @checkout_latest = argv.flag?("latest")
      @checkout_exact = argv.flag?("exact")
      super
    end
    
    def validate!
      super
      help! "You must specify a branch or commit id to checkout" unless @ref
      help! "You can't provide more than one operation modifier (--latest, --exact, etc.)" if @checkout_latest && @checkout_exact
    end
    
    def run
      validate_in_work_tree
      ensure_multirepo_initialized
      
      Console.log_step("Checking out #{@ref} and its dependencies...")
      
      # Find out the checkout mode based on command-line options
      mode = if @checkout_latest then
        CheckoutMode::LATEST
      elsif @checkout_exact then
        CheckoutMode::EXACT
      else
        CheckoutMode::AS_LOCK
      end
      
      main_repo_checkout_step(@ref)
      dependencies_checkout_step(mode, @ref)
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
            
    def main_repo_checkout_step(ref)
      main_repo = Repo.new(".")
      initial_revision = main_repo.current_branch || main_repo.head_hash
      
      unless main_repo.is_clean?
        raise MultiRepoException, "Can't checkout #{ref} because the main repo contains uncommitted changes"
      end
      
      unless main_repo.checkout(ref)
        raise MultiRepoException, "Couldn't perform checkout of main repo #{ref}!"
      end
      
      Console.log_substep("Checked out main repo #{ref}")
      
      unless LockFile.exists?
        main_repo.checkout(initial_revision)
        raise MultiRepoException, "This revision is not managed by multirepo. Checkout reverted."
      end
    end
    
    def dependencies_checkout_step(mode, ref = nil)
      config_entries = ConfigFile.load # Post-main-repo checkout config entries might be different than pre-checkout
      
      unless Utils.ensure_dependencies_clean(config_entries)
        main_repo.checkout(initial_revision)
        raise MultiRepoException, "'#{e.path}' contains uncommitted changes. Checkout reverted."
      end
      
      LockFile.load.each { |lock_entry| perform_dependency_checkout(config_entries, lock_entry, ref, mode) }
    end
    
    def perform_dependency_checkout(config_entries, lock_entry, ref, mode)
      # Find the config entry that matches the given lock entry
      config_entry = config_entries.select{ |config_entry| config_entry.id == lock_entry.id }.first
      
      # Make sure the repo exists on disk, and clone it if it doesn't
      # (in case the checked-out revision had an additional dependency)
      unless config_entry.repo.exists?
        Console.log_substep("Cloning missing dependency '#{config_entry.path}' from #{config_entry.url}")
        config_entry.repo.clone(config_entry.url)
      end
      
      # Find out the proper revision to checkout based on the checkout mode
      revision = case mode
      when CheckoutMode::AS_LOCK; lock_entry.head
      when CheckoutMode::LATEST; lock_entry.branch
      when CheckoutMode::EXACT; ref
      end
      
      # Checkout!
      if config_entry.repo.checkout(revision)
        Console.log_substep("Checked out #{lock_entry.name} #{revision}")
      else
        raise MultiRepoException, "Couldn't check out the appropriate version of dependency #{lock_entry.name}"
      end
    end
  end
end
require "multirepo/utility/console"
require "multirepo/logic/commit-selector"

module MultiRepo
  class CheckoutCommand < Command
    self.command = "checkout"
    self.summary = "Checks out the specified commit or branch of the main repo and checks out matching versions of all dependencies."
    
    def self.options
      [
        ['<ref>', 'The main repo tag, branch or commit id to checkout.'],
        ['[--latest]', 'Checkout the HEAD of each dependency branch (as recorded in the lock file) instead of the exact required commits.'],
        ['[--exact]', 'Checkout the exact specified ref for each repo, regardless of what\'s stored in the lock file.']
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
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      Console.log_step("Checking out #{@ref} and its dependencies...")
      
      # Find out the checkout mode based on command-line options
      mode = CommitSelector.mode_for_args(@checkout_latest, @checkout_exact)
      
      main_repo = Repo.new(".")
      initial_revision = main_repo.current_branch || main_repo.head_hash
      
      unless proceed_if_merge_commit?(main_repo, @ref, mode)
        raise MultiRepoException, "Aborting checkout"
      end
      
      main_repo_checkout_step(main_repo, initial_revision, @ref)
      ensure_dependencies_clean_step(main_repo, initial_revision)
      dependencies_checkout_step(mode, @ref)
            
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
            
    def main_repo_checkout_step(main_repo, initial_revision, ref)
      # Make sure the main repo is clean before attempting a checkout
      unless main_repo.is_clean?
        raise MultiRepoException, "Can't checkout #{ref} because the main repo contains uncommitted changes"
      end
      
      # Checkout the specified ref
      unless main_repo.checkout(ref)
        raise MultiRepoException, "Couldn't perform checkout of main repo #{ref}!"
      end
      
      Console.log_substep("Checked out main repo #{ref}")
      
      # After checkout, make sure we're working with a multirepo-enabled ref
      unless Utils.is_multirepo_tracked(".")
        main_repo.checkout(initial_revision)
        raise MultiRepoException, "This revision is not tracked by multirepo. Checkout reverted."
      end
    end
    
    def ensure_dependencies_clean_step(main_repo, initial_revision)
      unless Utils.ensure_dependencies_clean(ConfigFile.new(".").load_entries)
        main_repo.checkout(initial_revision)
        raise MultiRepoException, "Checkout reverted."
      end
    end
    
    def dependencies_checkout_step(mode, ref = nil)
      config_entries = ConfigFile.new(".").load_entries # Post-main-repo checkout config entries might be different than pre-checkout
      LockFile.new(".").load_entries.each { |lock_entry| perform_dependency_checkout(config_entries, lock_entry, ref, mode) }
    end
    
    def proceed_if_merge_commit?(main_repo, ref, mode)
      return true unless main_repo.commit(ref).is_merge?
      
      case mode
      when CommitSelectionMode::AS_LOCK
        Console.log_error("The specified ref is a merge commit and an \"as-lock\" checkout was requested.")
        Console.log_error("The resulting checkout would most probably not result in a valid project state.")
        return false
      when CommitSelectionMode::LATEST
        Console.log_warning("The specified ref is a merge commit and a \"latest\" checkout was requested.")
        Console.log_warning("The work branches recorded in the branch from which the merge was performed will be checked out.")
      end
      
      return true
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
      revision = CommitSelector.ref_for_mode(mode, ref, lock_entry)
      
      # Checkout!
      if config_entry.repo.checkout(revision)
        Console.log_substep("Checked out #{lock_entry.name} #{revision}")
      else
        raise MultiRepoException, "Couldn't check out the appropriate version of dependency #{lock_entry.name}"
      end
    end
  end
end
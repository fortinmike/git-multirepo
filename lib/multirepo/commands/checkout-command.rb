require "multirepo/utility/console"
require "multirepo/logic/revision-selector"
require "multirepo/logic/performer"

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
      
      Console.log_step("Checking out #{@ref} and its dependencies...")
        
      # Find out the checkout mode based on command-line options
      mode = RevisionSelector.mode_for_args(@checkout_latest, @checkout_exact)
      
      main_repo = Repo.new(".")
      
      unless proceed_if_merge_commit?(main_repo, @ref, mode)
        raise MultiRepoException, "Aborting checkout"
      end
      
      initial_revision = main_repo.current_branch || main_repo.head_hash
      begin
        # Checkout first because the current ref might not be multirepo-enabled
        checkout_main_repo_step(main_repo)
        
        # Only then can we check for dependencies and make sure they are clean
        ensure_dependencies_clean_step(main_repo)
      rescue MultiRepoException => e
        Console.log_error("Reverting main repo checkout")
        main_repo.checkout(initial_revision)
        raise e
      end
      dependencies_checkout_step(mode, @ref)
            
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def checkout_main_repo_step(main_repo)
      Performer.perform_main_repo_checkout(main_repo, @ref)
    end
    
    def ensure_dependencies_clean_step(main_repo)
      unless Utils.ensure_dependencies_clean(ConfigFile.new(".").load_entries)
        raise MultiRepoException, "Dependencies are not clean!"
      end
    end
    
    def dependencies_checkout_step(mode, ref = nil)
      Performer.perform_on_dependencies do |config_entry, lock_entry|
        # Find out the required dependency revision based on the checkout mode
        revision = RevisionSelector.ref_for_mode(mode, ref, lock_entry)
        perform_dependency_checkout(config_entry, revision)
      end
    end
    
    def proceed_if_merge_commit?(main_repo, ref, mode)
      return true unless main_repo.commit(ref).is_merge?
      
      case mode
      when RevisionSelectionMode::AS_LOCK
        Console.log_error("The specified ref is a merge commit and an \"as-lock\" checkout was requested.")
        Console.log_error("The resulting checkout would most probably not result in a valid project state.")
        return false
      when RevisionSelectionMode::LATEST
        Console.log_warning("The specified ref is a merge commit and a \"latest\" checkout was requested.")
        Console.log_warning("The work branches recorded in the branch from which the merge was performed will be checked out.")
      end
      
      return true
    end
    
    def perform_dependency_checkout(config_entry, revision)
      dependency_name = config_entry.repo.basename
      
      # Make sure the repo exists on disk, and clone it if it doesn't
      # (in case the checked-out revision had an additional dependency)
      unless config_entry.repo.exists?
        Console.log_substep("Cloning missing dependency '#{config_entry.path}' from #{config_entry.url}")
        config_entry.repo.clone(config_entry.url)
      end
      
      # Checkout!
      if config_entry.repo.checkout(revision)
        Console.log_substep("Checked out #{dependency_name} #{revision}")
      else
        raise MultiRepoException, "Couldn't check out the appropriate version of dependency #{dependency_name}"
      end
    end
  end
end
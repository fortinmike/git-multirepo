require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/output/extra-output"
require "multirepo/logic/revision-selector"
require "multirepo/logic/performer"

module MultiRepo
  class CheckoutCommand < Command
    self.command = "checkout"
    self.summary = "Checks out the specified commit or branch of the main repo and checks out matching versions of all dependencies."
    
    def self.options
      [
        ['<refname>', 'The main repo tag, branch or commit id to checkout.'],
        ['[--latest]', 'Checkout the HEAD of each dependency branch (as recorded in the lock file) instead of the exact stored commits.'],
        ['[--as-lock]', 'Checkout the exact commits for each repo based on the lock file, in detached head state.'],
        ['[--force]', 'Force checkout even if there are uncommmitted changes.']
      ].concat(super)
    end
    
    def initialize(argv)
      @ref_name = argv.shift_argument
      @checkout_latest = argv.flag?("latest")
      @checkout_lock = argv.flag?("as-lock")
      @force = argv.flag?("force")
      super
    end
    
    def validate!
      super
      help! "You must specify a branch or commit id to checkout" unless @ref_name
      unless Utils.only_one_true?(@checkout_latest, @checkout_lock)
        help! "You can't provide more than one operation modifier (--latest, --as-lock, etc.)"
      end
    end
    
    def run
      ensure_in_work_tree
      
      # Find out the checkout mode based on command-line options
      mode = RevisionSelector.mode_for_args(@checkout_latest, @checkout_lock)
      
      strategy_name = RevisionSelection.name_for_mode(mode)
      Console.log_step("Checking out #{@ref_name} and its dependencies using the '#{strategy_name}' strategy...")
      
      main_repo = Repo.new(".")
      
      unless proceed_if_merge_commit?(main_repo, @ref_name, mode)
        fail MultiRepoException, "Aborting checkout"
      end
      
      checkout_core(main_repo, mode)
            
      Console.log_step("Done!")
    end
    
    def checkout_core(main_repo, mode)
      initial_revision = main_repo.current_revision
      begin
        # Checkout first because the current ref might not be multirepo-enabled
        checkout_main_repo_step(main_repo)
        # Only then can we check for dependencies and make sure they are clean
        ensure_dependencies_clean_step if !@force
      rescue MultiRepoException => e
        Console.log_warning("Restoring working copy to #{initial_revision}")
        main_repo.checkout(initial_revision)
        raise e
      end
      dependencies_checkout_step(mode, @ref_name)
    end
    
    def checkout_main_repo_step(main_repo)
      Performer.perform_main_repo_checkout(main_repo, @ref_name, @force)
    end
    
    def ensure_dependencies_clean_step
      unless Utils.dependencies_clean?(ConfigFile.new(".").load_entries)
        fail MultiRepoException, "Dependencies are not clean!"
      end
    end
    
    def dependencies_checkout_step(mode, ref_name = nil, force = false)
      Performer.depth_ordered_dependencies.each do |dependency|
        # Find out the required dependency revision based on the checkout mode
        revision = RevisionSelector.revision_for_mode(mode, ref_name, dependency.lock_entry)
        perform_dependency_checkout(dependency.config_entry, revision, force)
      end
    end
    
    def proceed_if_merge_commit?(main_repo, ref_name, mode)
      return true unless main_repo.ref(ref_name).merge_commit?
      
      case mode
      when RevisionSelection::AS_LOCK
        Console.log_error("The specified ref is a merge commit and an \"as-lock\" checkout was requested.")
        Console.log_error("The resulting checkout would most probably not result in a valid project state.")
        return false
      when RevisionSelection::LATEST
        Console.log_warning("The specified ref is a merge commit and a \"latest\" checkout was requested.")
        Console.log_warning("The work branches recorded in the branch from which the merge was performed will be checked out.")
      end
      
      return true
    end
    
    def perform_dependency_checkout(config_entry, revision, force)
      dependency_name = config_entry.repo.basename
      
      # Make sure the repo exists on disk, and clone it if it doesn't
      # (in case the checked-out revision had an additional dependency)
      unless config_entry.repo.exists?
        Console.log_substep("Cloning missing dependency '#{config_entry.path}' from #{config_entry.url}")
        ExtraOutput.progress("Cloning missing dependency #{config_entry.path}")
        config_entry.repo.clone(config_entry.url)
      end
      
      # Checkout!
      ExtraOutput.progress("Checking out #{dependency_name} #{revision}")
      if config_entry.repo.checkout(revision, force)
        Console.log_substep("Checked out #{dependency_name} '#{revision}'")
      else
        ExtraOutput.error("Couldn|'t check out dependency #{dependency_name}")
        fail MultiRepoException, "Couldn't check out the appropriate version of dependency #{dependency_name}"
      end
    end
  end
end

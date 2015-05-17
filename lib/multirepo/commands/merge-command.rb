require "terminal-table"

require "multirepo/utility/console" 
require "multirepo/logic/node"
require "multirepo/logic/revision-selector"
require "multirepo/logic/performer"
require "multirepo/logic/merge-descriptor"

module MultiRepo
  class MergeCommand < Command
    self.command = "merge"
    self.summary = "Performs a git merge on all dependencies and the main repo, in the proper order."
    
    def self.options
      [
        ['<refname>', 'The main repo tag, branch or commit id to merge.'],
        ['[--latest]', 'Merge the HEAD of each stored dependency branch instead of the commits recorded in the lock file.'],
        ['[--exact]', 'Merge the exact specified ref for each repo, regardless of what\'s stored in the lock file.']
      ].concat(super)
    end
    
    def initialize(argv)
      @ref_name = argv.shift_argument
      @checkout_latest = argv.flag?("latest")
      @checkout_exact = argv.flag?("exact")
      super
    end
    
    def validate!
      super
      help! "You must specify a ref to merge" unless @ref_name
      unless validate_only_one_flag(@checkout_latest, @checkout_exact)
        help! "You can't provide more than one operation modifier (--latest, --exact, etc.)"
      end
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      # Find out the checkout mode based on command-line options
      mode = RevisionSelector.mode_for_args(@checkout_latest, @checkout_exact)
      
      strategy_name = RevisionSelectionMode.name_for_mode(mode)
      Console.log_step("Merging #{@ref_name} with '#{strategy_name}' strategy...")
      
      main_repo = Repo.new(".")
      
      # Keep the initial revision because we're going to need to come back to it later
      initial_revision = main_repo.current_revision
      
      begin
        merge_core(main_repo, initial_revision, mode)
      rescue MultiRepoException => e
        # Revert to the initial revision only if necessary
        unless main_repo.current_revision == initial_revision
          Console.log_warning("Restoring working copy to #{initial_revision}")
          main_repo.checkout(initial_revision)
        end
        raise e
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def merge_core(main_repo, initial_revision, mode)
      config_file = ConfigFile.new(".")
      lock_file = LockFile.new(".")
      
      # Load entries prior to checkout so that we can compare them later
      our_config_entries = config_file.load_entries
      our_lock_entries = lock_file.load_entries
      
      # Ensure the main repo is clean
      raise MultiRepoException, "Main repo is not clean; merge aborted" unless main_repo.is_clean?
      
      # Ensure dependencies are clean
      unless Utils.ensure_dependencies_clean(our_config_entries)
        raise MultiRepoException, "Dependencies are not clean; merge aborted"
      end
      
      # Fetch repos to make sure we have the latest history in each.
      # Fetching pre-checkout dependency repositories is sufficient because
      # we make sure that the same dependencies are configured post-checkout.
      Console.log_substep("Fetching repositories before proceeding with merge...")
      main_repo.fetch
      our_config_entries.each { |e| e.repo.fetch }
      
      # Checkout the specified main repo ref to find out which dependency refs to merge
      Performer.perform_main_repo_checkout(main_repo, @ref_name)
      
      # Load entries for the ref we're going to merge
      their_config_entries = config_file.load_entries
      their_lock_entries = lock_file.load_entries
      
      # Checkout the initial revision ASAP
      Performer.perform_main_repo_checkout(main_repo, initial_revision)
      
      # Build dependencies for subsequent validation and iteration
      our_dependencies = Performer.dependencies_with_entries(our_config_entries, our_lock_entries)
      their_dependencies = Performer.dependencies_with_entries(their_config_entries, their_lock_entries)
      
      # Auto-merge would be too complex to implement (due to lots of edge cases)
      # if the specified ref does not have the same dependencies. Better perform a manual merge.
      ensure_dependencies_match(our_dependencies, their_dependencies)
      
      # Create a merge descriptor for each would-be merge
      # while we're in *our* working copy
      descriptors = []
      our_dependencies.zip(their_dependencies).each do |our_dependency, their_dependency|
        our_revision = our_dependency.config_entry.repo.current_revision
        
        their_revision = RevisionSelector.revision_for_mode(mode, @ref_name, their_dependency.lock_entry)
        their_name = their_dependency.config_entry.name
        their_repo = their_dependency.config_entry.repo
        
        descriptor = MergeDescriptor.new(their_name, their_repo, our_revision, their_revision)
        
        descriptors.push(descriptor)
      end
      descriptors.push(MergeDescriptor.new("Main Repo", main_repo, main_repo.current_revision, @ref_name))
            
      # Log merge operations to the console before the fact
      Console.log_info("Merging would #{message_for_mode(mode, @ref_name)}:")
      log_merges(descriptors)
      ensure_merges_valid(descriptors)
      
      raise MultiRepoException, "Merge aborted" unless Console.ask_yes_no("Proceed?")
      
      Console.log_step("Performing merge...")
      
      # Merge dependencies and the main repo
      perform_merges(descriptors)
    end
    
    def ensure_dependencies_match(our_dependencies, their_dependencies)
      our_dependencies.zip(their_dependencies).each do |our_dependency, their_dependency|
        if their_dependency == nil || their_dependency.config_entry.id != our_dependency.config_entry.id
          raise MultiRepoException, "Dependencies differ, please merge manually"
        end
      end
      
      if their_dependencies.count > our_dependencies.count
        raise MultiRepoException, "There are more dependencies in the specified ref, please merge manually"
      end
    end
    
    def log_merges(descriptors)
      table = Terminal::Table.new do |t|
        descriptors.reverse.each_with_index do |descriptor, index|
          t.add_row [descriptor.name.bold, descriptor.merge_description, descriptor.upstream_description]
          t.add_separator unless index == descriptors.count - 1
        end
      end
      puts table
    end
    
    def ensure_merges_valid(descriptors)
      if descriptors.any? { |d| d.state == TheirState::LOCAL_NO_UPSTREAM }
        Console.log_warning("Some branches are not remote-tracking! Please review the merge operations above.")
      elsif descriptors.any? { |d| d.state == TheirState::LOCAL_UPSTREAM_DIVERGED }
        raise MultiRepoException, "Some upstream branches have diverged. This warrants a manual merge!"
      end
    end
    
    def perform_merges(descriptors)
      descriptors.each do |descriptor|
        Console.log_substep("#{descriptor.name} : Merging #{descriptor.revision} into current branch...")
        GitRunner.run_in_working_dir(descriptor.path, "merge #{descriptor.revision}", Runner::Verbosity::OUTPUT_ALWAYS)
      end
    end
    
    def message_for_mode(mode, ref_name)
      case mode
      when RevisionSelectionMode::AS_LOCK
        "merge specific commits as stored in the lock file for main repo revision #{ref_name}"
      when RevisionSelectionMode::LATEST
        "merge each branch as stored in the lock file of main repo revision #{ref_name}"
      when RevisionSelectionMode::EXACT
        "merge #{ref_name} for each repository, ignoring the contents of the lock file"
      end
    end
  end
end
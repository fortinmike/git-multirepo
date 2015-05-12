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
        ['<ref>', 'The main repo tag, branch or commit id to merge.'],
        ['[--latest]', 'Merge the HEAD of each stored dependency branch instead of the commits recorded in the lock file.'],
        ['[--exact]', 'Merge the exact specified ref for each repo, regardless of what\'s stored in the lock file.']
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
      help! "You must specify a ref to merge" unless @ref
      help! "You can't provide more than one operation modifier (--latest, --exact, etc.)" if @checkout_latest && @checkout_exact
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      # Find out the checkout mode based on command-line options
      mode = RevisionSelector.mode_for_args(@checkout_latest, @checkout_exact)
      
      strategy_name = RevisionSelectionMode.name_for_mode(mode)
      Console.log_step("Merging #{@ref} with '#{strategy_name}' strategy...")
      
      main_repo = Repo.new(".")
      
      # Keep the initial revision because we're going to need to come back to it later
      initial_revision = main_repo.current_branch || main_repo.head_hash
      
      begin
        merge_core(main_repo, initial_revision, mode)
      rescue MultiRepoException => e
        # Revert to the initial revision only if necessary
        unless main_repo.current_branch == initial_revision || main_repo.head_hash == initial_revision
          Console.log_substep("Restoring working copy to #{initial_revision}")
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
      
      # Load entries prior to checkout so that we can compare them later
      pre_checkout_config_entries = config_file.load_entries
      
      # Ensure the main repo is clean
      raise MultiRepoException, "Main repo is not clean; merge aborted" unless main_repo.clean?
      
      # Ensure dependencies are clean
      unless Utils.ensure_dependencies_clean(pre_checkout_config_entries)
        raise MultiRepoException, "Dependencies are not clean; merge aborted"
      end
      
      # Fetch repos to make sure we have the latest history in each.
      # Fetching pre-checkout dependency repositories is sufficient because
      # we make sure that the same dependencies are configured post-checkout.
      Console.log_substep("Fetching repositories before proceeding with merge...")
      main_repo.fetch
      pre_checkout_config_entries.each { |e| e.repo.fetch }
      
      # Checkout the specified main repo ref to find out which dependency refs to merge
      Performer.perform_main_repo_checkout(main_repo, @ref)
      
      # Load config entries for the ref we're going to merge
      post_checkout_config_entries = config_file.load_entries
      
      # Auto-merge would be too complex to implement (due to lots of edge cases)
      # if the specified ref does not have the same dependencies
      ensure_dependencies_match(pre_checkout_config_entries, post_checkout_config_entries)
      
      # Create a merge descriptor for each would-be merge
      descriptors = []
      Performer.perform_on_dependencies do |config_entry, lock_entry|
        revision = RevisionSelector.revision_for_mode(mode, @ref, lock_entry)
        descriptors.push(MergeDescriptor.new(config_entry.name, config_entry.path, revision))
      end
      descriptors.push(MergeDescriptor.new("[main repo]", main_repo.path, @ref))
            
      # Log merge operations to the console before the fact
      Console.log_warning("Merging would #{message_for_mode(mode, @ref)}:")
      log_merges(descriptors)
      
      raise MultiRepoException, "Merge aborted" unless Console.ask_yes_no("Proceed?")
      
      Console.log_step("Performing merge...")
      
      # Checkout the initial revision to perform the merge in it
      Performer.perform_main_repo_checkout(main_repo, initial_revision)
      
      # Merge dependencies and the main repo
      perform_merges(descriptors)
    end
    
    def ensure_dependencies_match(pre_checkout_config_entries, post_checkout_config_entries)
      perfect_match = true
      pre_checkout_config_entries.each do |pre_entry|
        found = post_checkout_config_entries.find { |post_entry| post_entry.id = pre_entry.id }
        perfect_match &= found
        Console.log_warning("Dependency '#{pre_entry.repo.path}' was not found in the target ref") unless found
      end
      
      unless perfect_match
        raise MultiRepoException, "Dependencies differ, please merge manually"
      end
      
      if post_checkout_config_entries.count > pre_checkout_config_entries.count
        raise MultiRepoException, "There are more dependencies in the specified ref, please merge manually"
      end
    end
    
    def log_merges(descriptors)
      descriptors.each do |descriptor|
        Console.log_info("#{descriptor.name} : Merge #{descriptor.revision} into current branch")
      end
    end
    
    def message_for_mode(mode, ref)
      case mode
      when RevisionSelectionMode::AS_LOCK
        "merge specific commits as stored in the lock file for main repo revision #{ref}"
      when RevisionSelectionMode::LATEST
        "merge each branch as stored in the lock file of main repo revision #{ref}"
      when RevisionSelectionMode::EXACT
        "merge #{ref} for each repository, ignoring the contents of the lock file"
      end
    end
    
    def perform_merges(descriptors)
      descriptors.each do |descriptor|
        Console.log_substep("#{descriptor.name} : Merging #{descriptor.revision} into current branch...")
        GitRunner.run_in_working_dir(descriptor.path, "merge #{descriptor.revision}", Runner::Verbosity::OUTPUT_ALWAYS)
      end
    end
  end
end
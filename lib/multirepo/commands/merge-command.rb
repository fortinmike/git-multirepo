require "terminal-table"

require "multirepo/utility/console" 
require "multirepo/logic/node"
require "multirepo/logic/revision-selector"
require "multirepo/logic/performer"
require "multirepo/logic/merge-descriptor"
require "multirepo/files/tracking-files"

module MultiRepo
  class MergeValidationResult
    ABORT = 0
    PROCEED = 1
    MERGE_UPSTREAM = 2
    
    attr_accessor :outcome
    attr_accessor :message
  end
  
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
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      # Find out the checkout mode based on command-line options
      mode = RevisionSelector.mode_for_args(@checkout_latest, @checkout_exact)
      
      strategy_name = RevisionSelection.name_for_mode(mode)
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
    end
    
    def merge_core(main_repo, initial_revision, mode)
      config_file = ConfigFile.new(".")
      
      # Ensure the main repo is clean
      fail MultiRepoException, "Main repo is not clean; merge aborted" unless main_repo.clean?
      
      # Ensure dependencies are clean
      unless Utils.dependencies_clean?(config_file.load_entries)
        fail MultiRepoException, "Dependencies are not clean; merge aborted"
      end
      
      ref_name = @ref_name
      descriptors = nil
      loop do
        # Gather information about the merges that would occur
        descriptors = build_merge(main_repo, initial_revision, ref_name, mode)
      
        # Preview merge operations in the console
        preview_merge(descriptors, mode, ref_name)
        
        # Validate merge operations
        result = ensure_merge_valid(descriptors)
        
        case result.outcome
        when MergeValidationResult::ABORT
          fail MultiRepoException, result.message
        when MergeValidationResult::PROCEED
          fail MultiRepoException, "Merge aborted" unless Console.ask("Proceed?")
          Console.log_warning(result.message) if result.message
          break
        when MergeValidationResult::MERGE_UPSTREAM
          Console.log_warning(result.message)
          fail MultiRepoException, "Merge aborted" unless Console.ask("Merge upstream instead of local branches?")
          # TODO: Modify operations!
          fail MultiRepoException, "Fallback behavior not implemented. Please merge manually."
          next
        end
        
        fail MultiRepoException, "Merge aborted" unless Console.ask("Proceed?")
      end
      
      Console.log_step("Performing merge...")
      
      all_succeeded = perform_merges(descriptors)
      ask_tracking_files_update(all_succeeded)
    end
    
    def build_merge(main_repo, initial_revision, ref_name, mode)
      # List dependencies prior to checkout so that we can compare them later
      our_dependencies = Performer.dependencies
      
      # Checkout the specified main repo ref to find out which dependency refs to merge
      commit_id = Ref.new(main_repo, ref_name).commit_id # Checkout in floating HEAD
      Performer.perform_main_repo_checkout(main_repo, commit_id, "Checked out main repo '#{ref_name}' to inspect to-merge dependencies")
      
      # List dependencies for the ref we're trying to merge
      their_dependencies = Performer.dependencies
      
      # Checkout the initial revision ASAP
      Performer.perform_main_repo_checkout(main_repo, initial_revision, "Checked out initial main repo revision '#{initial_revision}'")
      
      # Auto-merge would be too complex to implement (due to lots of edge cases)
      # if the specified ref does not have the same dependencies. Better perform a manual merge.
      ensure_dependencies_match(our_dependencies, their_dependencies)
      
      # Create a merge descriptor for each would-be merge as well as the main repo.
      # This step MUST be performed in OUR revision for the merge descriptors to be correct!
      descriptors = build_dependency_merge_descriptors(our_dependencies, their_dependencies, ref_name, mode)
      descriptors.push(MergeDescriptor.new("Main Repo", main_repo, initial_revision, ref_name))
      
      return descriptors
    end
    
    def build_dependency_merge_descriptors(our_dependencies, their_dependencies, ref_name, mode)
      descriptors = []
      our_dependencies.zip(their_dependencies).each do |our_dependency, their_dependency|
        our_revision = our_dependency.config_entry.repo.current_revision
        
        their_revision = RevisionSelector.revision_for_mode(mode, ref_name, their_dependency.lock_entry)
        their_name = their_dependency.config_entry.name
        their_repo = their_dependency.config_entry.repo
        
        descriptor = MergeDescriptor.new(their_name, their_repo, our_revision, their_revision)
        
        descriptors.push(descriptor)
      end
      return descriptors
    end
    
    def ensure_dependencies_match(our_dependencies, their_dependencies)
      our_dependencies.zip(their_dependencies).each do |our_dependency, their_dependency|
        if their_dependency.nil? || their_dependency.config_entry.id != our_dependency.config_entry.id
          fail MultiRepoException, "Dependencies differ, please merge manually"
        end
      end
      
      if their_dependencies.count > our_dependencies.count
        fail MultiRepoException, "There are more dependencies in the specified ref, please merge manually"
      end
    end
    
    def preview_merge(descriptors, mode, ref_name)
      Console.log_info("Merging would #{message_for_mode(mode, ref_name)}:")
      
      table = Terminal::Table.new do |t|
        descriptors.reverse.each_with_index do |descriptor, index|
          t.add_row [descriptor.name.bold, descriptor.merge_description, descriptor.upstream_description]
          t.add_separator unless index == descriptors.count - 1
        end
      end
      puts table
    end
    
    def ensure_merge_valid(descriptors)
      outcome = MergeValidationResult.new
      outcome.outcome = MergeValidationResult::PROCEED
      
      if descriptors.any? { |d| d.state == TheirState::LOCAL_NO_UPSTREAM }
        outcome.message = "Some branches are not remote-tracking! Please review the merge operations above."
      elsif descriptors.any? { |d| d.state == TheirState::LOCAL_UPSTREAM_DIVERGED }
        outcome.outcome = MergeValidationResult::ABORT
        outcome.message = "Some upstream branches have diverged. This warrants a manual merge!"
      elsif descriptors.any? { |d| d.state == TheirState::LOCAL_OUTDATED }
        outcome.outcome = MergeValidationResult::MERGE_UPSTREAM
        outcome.message = "Some local branches are outdated"
      end
      
      return outcome
    end
    
    def perform_merges(descriptors)
      success = true
      descriptors.each do |descriptor|
        Console.log_substep("#{descriptor.name} : Merging #{descriptor.their_revision} into #{descriptor.our_revision}...")
        GitRunner.run_as_system(descriptor.repo.path, "merge #{descriptor.their_revision}")
        success &= GitRunner.last_command_succeeded
      end
      
      if success
        Console.log_info("All merges performed successfully!")
      else
        Console.log_warning("Some merge operations failed. Please review the above.")
      end
      
      return success
    end
    
    def ask_tracking_files_update(all_merges_succeeded)
      unless all_merges_succeeded
        Console.log_warning("Perform a manual update using 'multi update' after resolving merge conflicts")
        return
      end
      
      return unless Console.ask("Update main repo tracking files (important for continuous integration)?")
      
      tracking_files = TrackingFiles.new(".")
      tracking_files.update
      tracking_files.commit("[multirepo] Post-merge tracking files update")
      
      Console.log_info("Updated and committed tracking files in the main repo")
    end
    
    def message_for_mode(mode, ref_name)
      case mode
      when RevisionSelection::AS_LOCK
        "merge specific commits as stored in the lock file for main repo revision #{ref_name}"
      when RevisionSelection::LATEST
        "merge each branch as stored in the lock file of main repo revision #{ref_name}"
      when RevisionSelection::EXACT
        "merge #{ref_name} for each repository, ignoring the contents of the lock file"
      end
    end
  end
end

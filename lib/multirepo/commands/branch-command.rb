require "multirepo/utility/console"
require "multirepo/git/git"
require "multirepo/files/config-file"
require "multirepo/files/tracking-files"
require "multirepo/logic/performer"

module MultiRepo
  class BranchCommand < Command
    self.command = "branch"
    self.summary = "Create and/or checkout a new branch for all repos."
    
    def self.options
      [
        ['<branch name>', 'The name of the branch to create and checkout.'],
        ['[--force]', 'Force creating the branch even if there are uncommmitted changes.'],
        ['[--push]', 'Push the branch on creation.']
      ].concat(super)
    end
    
    def initialize(argv)
      @branch_name = argv.shift_argument
      @force = argv.flag?("force")
      @push = argv.flag?("push", false)
      super
    end
    
    def validate!
      super
      help! "You must specify a branch name" unless @branch_name
      help! "Please provide a valid branch name" unless Git.valid_branch_name?(@branch_name)
    end
    
    def run
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      Console.log_step("Branching...")
      
      main_repo = Repo.new(".")
      
      unless @force
        # Ensure the main repo is clean
        fail MultiRepoException, "Main repo is not clean; multi branch aborted" unless main_repo.clean?
        
        # Ensure dependencies are clean
        config_entries = ConfigFile.new(".").load_entries
        unless Utils.dependencies_clean?(config_entries)
          fail MultiRepoException, "Dependencies are not clean; multi branch aborted"
        end
      end

      # Branch dependencies
      Performer.depth_ordered_dependencies.each do |dependency|
        perform_branch(dependency.config_entry.repo)
      end
      
      # Branch the main repo
      perform_branch(main_repo)
      
      Console.log_step("Done!")
    end
    
    def perform_branch(repo)
      Console.log_substep("Branching '#{repo.path}' ...")
      Console.log_info("Creating and checking out branch #{@branch_name} ...")
      
      branch = repo.branch(@branch_name)
      branch.create unless branch.exists?
      branch.checkout
      
      if Utils.multirepo_enabled?(repo.path)
        Console.log_info("Updating and committing tracking files")
        tracking_files = TrackingFiles.new(repo.path)
        tracking_files.update
        tracking_files.commit("[multirepo] Post-branch tracking files update")
      end
      
      return unless @push
      
      if @force
        Console.log_warning("Skipping #{@branch_name} branch push because we're force-branching")
      else
        Console.log_info("Pushing #{@branch_name} to origin/#{@branch_name}")
        repo.branch(@branch_name).push
      end
    end
  end
end

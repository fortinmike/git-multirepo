require "multirepo/utility/console"
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
        ['[--force]', 'Force creating the branch even if the repos contain uncommmitted changes.'],
        ['[--no-push]', 'Do not push the branch on creation.']
      ].concat(super)
    end
    
    def initialize(argv)
      @branch_name = argv.shift_argument
      @force = argv.flag?("force")
      @remote_tracking = argv.flag?("push", true)
      super
    end
    
    def validate!
      super
      help! "You must specify a branch name" unless @branch_name
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      Console.log_step("Branching...")
      
      main_repo = Repo.new(".")
      
      # Ensure the main repo is clean
      raise MultiRepoException, "Main repo is not clean; multi branch aborted" unless main_repo.clean?
      
      # Ensure dependencies are clean
      config_entries = ConfigFile.new(".").load_entries
      unless Utils.ensure_dependencies_clean(config_entries)
        raise MultiRepoException, "Dependencies are not clean; multi branch aborted"
      end
      
      # Branch dependencies
      Performer.perform_on_dependencies do |config_entry, lock_entry|
        perform_branch(config_entry.repo)
      end
      
      # Branch the main repo
      perform_branch(main_repo)
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def perform_branch(repo)
      log_operation(repo.path, @branch_name, @remote_tracking)
      
      branch = repo.branch(@branch_name)
      branch.create unless branch.exists?
      branch.checkout
      
      if Utils.is_multirepo_enabled(repo.path)
        Console.log_substep("Updating and committing tracking files in multirepo-enabled repo")
        tracking_files = TrackingFiles.new(repo.path)
        tracking_files.update
        tracking_files.commit("[multirepo] Post-branch tracking files update")
      end
      
      repo.branch(@branch_name).push if @remote_tracking
    end
    
    def log_operation(path, branch_name, remote_tracking)
      if remote_tracking
        Console.log_substep("Branching, checking out and pushing '#{path}' #{branch_name} ...")
      else
        Console.log_substep("Branching and checking out '#{path}' #{branch_name} (not pushed) ...")
      end
    end
  end
end
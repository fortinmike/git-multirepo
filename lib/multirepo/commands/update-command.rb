require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/logic/performer"
require "multirepo/logic/repo-selection"
require "multirepo/files/tracking-files"
require "multirepo/git/git-runner"

module MultiRepo
  class UpdateCommand < Command
    self.command = "update"
    self.summary = "Force-updates the multirepo tracking files."
    
    def self.options
      [
        ['[--all]', 'Update the main repository and all dependencies.'],
        ['[--main]', 'Update the main repository.'],
        ['[--deps]', 'Update dependencies.'],
        ['[--force]', 'Update the tracking files even if dependencies contain uncommitted changes.'],
        ['[--commit]', 'Commit the tracking files after updating them.']
      ].concat(super)
    end
    
    def initialize(argv)
      @repo_selection = RepoSelection.new(argv)
      @commit = argv.flag?("commit")
      @force = argv.flag?("force")
      @diff = argv.flag?("diff", true)
      super
    end

    def validate!
      super
      help! "You can't provide more than one operation modifier (--deps, --main, etc.)" unless @repo_selection.valid?
    end

    def run
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      dependencies_clean = Utils.dependencies_clean?(ConfigFile.new(".").load_entries)
      if dependencies_clean || @force
        update_tracking_files_step(@repo_selection.value)
      else
        fail MultiRepoException, "Can't update because not all dependencies are clean"
      end
      
      Console.log_step("Done!")
    end
    
    def update_tracking_files_step(repo_selection_value)
      case repo_selection_value
      when RepoSelection::MAIN
        Console.log_step("Updating main repo...")
        update_main
      when RepoSelection::DEPS
        Console.log_step("Updating dependencies...")
        update_dependencies
      when RepoSelection::ALL
        Console.log_step("Updating main repo and dependencies...")
        update_dependencies
        update_main
      end
    end

    def update_dependencies
      any_changed = false
      Performer.dependencies.each do |dependency|
        path = dependency.config_entry.path
        name = dependency.config_entry.name
        any_changed |= update_one(path, name) if Utils.multirepo_enabled?(path)
      end
      return any_changed
    end

    def update_main
      update_one(".", "main repo")
    end

    def update_one(path, name)
      updated = update_tracking_files(path, name)
      show_diff(path) if updated && @diff
      commit_tracking_files(path) if @commit
      return updated
    end
    
    def update_tracking_files(path, name)
      Console.log_substep("Updating tracking files in #{name}")
      
      tracking_files = TrackingFiles.new(path)
      changed = tracking_files.update
      
      if changed
        Console.log_info("Updated tracking files")
      else
        Console.log_info("Tracking files are already up-to-date")
      end
      
      return changed
    end

    def commit_tracking_files(path)
      tracking_files = TrackingFiles.new(path)
      committed = tracking_files.commit("[multirepo] Updated tracking files manually")
      Console.log_info("Committed tracking files") if committed
    end

    def show_diff(path)
      GitRunner.run_as_system(path, "diff .multirepo.lock")
    end
  end
end

require "multirepo/utility/console"
require "multirepo/logic/performer"
require "multirepo/files/tracking-files"

module MultiRepo
  class UpdateCommand < Command
    self.command = "update"
    self.summary = "Force-updates the multirepo tracking files."
    
    def self.options
      [
        ['[--force]', 'Update the tracking files even if dependencies contain uncommitted changes.'],
        ['[--commit]', 'Commit the tracking files after updating them.']
      ].concat(super)
    end
    
    def initialize(argv)
      @commit = argv.flag?("commit")
      @force = argv.flag?("force")
      super
    end

    def run
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      Console.log_step("Updating...")
      
      dependencies_clean = Utils.dependencies_clean?(ConfigFile.new(".").load_entries)
      if dependencies_clean || @force
        update_tracking_files_step
      else
        fail MultiRepoException, "Can't update because not all dependencies are clean"
      end
      
      Console.log_step("Done!")
    end
    
    def update_tracking_files_step
      Performer.dependencies.each do |dependency|
        path = dependency.config_entry.path
        name = dependency.config_entry.name
        update_tracking_files(path, name) if Utils.multirepo_enabled?(path)
      end
      update_tracking_files(".", "main repo")
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
      
      if @commit
        committed = tracking_files.commit("[multirepo] Updated tracking files manually")
        Console.log_info("Committed tracking files") if committed
      end
    end
  end
end

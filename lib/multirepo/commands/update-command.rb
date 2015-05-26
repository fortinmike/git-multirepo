require "multirepo/utility/console"
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
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      Console.log_step("Updating...")
      
      dependencies_clean = Utils.ensure_dependencies_clean(ConfigFile.new(".").load_entries)
      if dependencies_clean
        update_lock_file_step("Updated tracking files")
      elsif !dependencies_clean && @force
        update_lock_file_step("Force-updated tracking files (ignoring uncommitted changes)")
      else
        raise MultiRepoException, "Can't update because not all dependencies are clean"
      end
      
      Console.log_step("Done!")
    end
    
    def update_lock_file_step(log_message)
      tracking_files = TrackingFiles.new(".")
      changed = tracking_files.update
      
      if changed
        Console.log_substep("Updated tracking files")
      else
        Console.log_substep("Tracking files are already up-to-date")
      end
      
      if @commit
        committed = tracking_files.commit("[multirepo] Updated tracking files manually")
        Console.log_substep("Committed tracking files") if committed
      end
    end
  end
end
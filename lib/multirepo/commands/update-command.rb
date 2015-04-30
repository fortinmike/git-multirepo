require "multirepo/utility/console"

module MultiRepo
  class UpdateCommand < Command
    self.command = "update"
    self.summary = "Force-updates the multirepo lock file."
    
    def self.options
      [
        ['[--force]', 'Update the lock file even if dependencies contain uncommitted changes.'],
        ['[--commit]', 'Commit the lock file after updating it.']
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
      
      dependencies_clean = Utils.ensure_dependencies_clean(ConfigFile.load)
      if dependencies_clean
        update_lock_file_step("Updated lock file with latest dependency commits")
      elsif !dependencies_clean && @force
        update_lock_file_step("Force-updated lock file with latest dependency commits (ignoring uncommitted changes)")
      else
        raise MultiRepoException, "Can't update because not all dependencies are clean"
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def update_lock_file_step(log_message)
      changed = LockFile.update
      
      if changed && @commit
        Console.log_substep("Committing updated lock file")
        LockFile.commit("[multirepo] Manually updated lock file")
      elsif changed
        Console.log_substep(log_message)
      else
        Console.log_info("Lock file is already up-to-date")
      end
    end
  end
end
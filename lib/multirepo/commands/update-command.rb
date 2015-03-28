require "multirepo/utility/console"

module MultiRepo
  class UpdateCommand < Command
    self.command = "update"
    self.summary = "Force-updates the multirepo lock file."
    
    def self.options
      [
        ['--force', 'Update the lock file even if dependencies contain uncommitted changes.'],
        ['--commit', 'Commit the lock file after updating it.']
      ].concat(super)
    end
    
    def initialize(argv)
      @commit = argv.flag?("commit")
      @force = argv.flag?("force")
      super
    end

    def run
      validate_in_work_tree
      ensure_multirepo_initialized
      
      Console.log_step("Updating...")
      
      dependencies_clean = Utils.ensure_dependencies_clean(ConfigFile.load)
      
      if dependencies_clean
        LockFile.update
        Console.log_substep("Updated lock file with latest dependency commits")
      elsif !dependencies_clean && @force
        LockFile.update
        Console.log_warning("Updated lock file with latest dependency commits regardless of uncommitted changes")
      else
        raise MultiRepoException, "Can't update because not all dependencies are clean"
      end
      
      install_hooks

      if @commit
        Console.log_substep("Committing updated lock file")
        LockFile.commit
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
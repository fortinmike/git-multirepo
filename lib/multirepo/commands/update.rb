require "multirepo/utility/console"

module MultiRepo
  class Update < Command
    self.command = "update"
    self.summary = "Force-updates the multirepo lock file."
    
    def run
      super
      ensure_multirepo_initialized
      
      Console.log_step("Updating...")
      
      LockFile.update
      Console.log_substep("Updated lock file")
      
      self.install_pre_commit_hook
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
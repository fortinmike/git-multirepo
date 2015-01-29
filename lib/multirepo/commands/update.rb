require "multirepo/utility/console"

module MultiRepo
  class Update < Command
    self.command = "update"
    self.summary = "Force-updates the multirepo lock file."
    
    def run
      super
      ensure_multirepo_initialized
      
      LockFile.update
      
      Console.log_step("Lock file updated")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
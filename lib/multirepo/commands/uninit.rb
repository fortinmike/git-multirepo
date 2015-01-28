require "multirepo/utility/console"

module MultiRepo
  class Uninit < Command
    self.command = "uninit"
    self.summary = "Removes all traces of multirepo in the current multirepo repository."
    
    def run
      super
      ensure_multirepo_initialized
      
      File.delete(".multirepo")
      File.delete(".multirepo.lock")
      File.delete(".git/hooks/pre-commit")
      
      Console.log_step("All traces of multirepo have been removed from this repository")
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
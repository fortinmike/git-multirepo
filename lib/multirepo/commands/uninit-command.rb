require "multirepo/utility/console"

module MultiRepo
  class UninitCommand < Command
    self.command = "uninit"
    self.summary = "Removes all traces of multirepo in the current multirepo repository."
    
    def run
      validate_in_work_tree
      ensure_multirepo_initialized
      
      File.delete(".multirepo")
      File.delete(".multirepo.lock")
      File.delete(".git/hooks/pre-commit")
      File.delete(".git/hooks/post-merge")
      
      Console.log_step("All traces of multirepo have been removed from this repository")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
require "multirepo/utility/console"

module MultiRepo
  class UninitCommand < Command
    self.command = "uninit"
    self.summary = "Removes all traces of multirepo in the current multirepo repository."
    
    def run
      super
      validate_in_work_tree
      
      FileUtils.rm_f(".multirepo")
      FileUtils.rm_f(".multirepo.lock")
      uninstall_hooks
      
      Console.log_step("All traces of multirepo have been removed from this repository")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
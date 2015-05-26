require "multirepo/utility/console"

module MultiRepo
  class UninitCommand < Command
    self.command = "uninit"
    self.summary = "Removes all traces of multirepo in the current multirepo repository."
    
    def run
      super
      ensure_in_work_tree
      
      FileUtils.rm_f(".multirepo")
      TrackingFiles.new(".").delete
      uninstall_hooks
      
      Console.log_step("All traces of multirepo have been removed from this repository")
    end
  end
end
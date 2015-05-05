require "multirepo/utility/console"
require "multirepo/model/dependency"

module MultiRepo
  class MergeCommand < Command
    self.command = "merge"
    self.summary = "Performs a git merge on all dependencies, in the proper order."
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      root_dependency = Dependency.new(".")
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
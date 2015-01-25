require "claide"

require "multirepo"
require "multirepo/utility/console"
require "multirepo/git/repo"
require "multirepo/loader"

module MultiRepo
  class Setup < Command
    self.command = "install"
    self.summary = "Clones and checks out repositories as defined in the .multirepo file, and installs git-multirepo's local pre-commit hook."
    
    def run
      super
      
      Console.log_step("Setupping multiple repositories...")
      
      @entries.each(&:install)
      
      MultiRepo.install_pre_commit_hook
      Console.log_substep("Installed pre-commit hook")
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
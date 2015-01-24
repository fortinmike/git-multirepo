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
      install_pre_commit_hook
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
    
    def install_pre_commit_hook
      hook_path = File.join(MultiRepo.path, "resources/pre-commit")
      FileUtils.cp(hook_path, ".git/hooks")
      Console.log_substep("Installed multirepo pre-commit hook")
    end
  end
end
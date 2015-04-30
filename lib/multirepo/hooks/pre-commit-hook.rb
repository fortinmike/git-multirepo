require "multirepo/files/config-file"
require "multirepo/files/lock-file"
require "multirepo/utility/utils"
require "multirepo/utility/console"

module MultiRepo
  class PreCommitHook
    def self.run
      Config.instance.running_git_hook = true
      
      Console.log_step("Performing pre-commit operations...")
      
      dependencies_clean = Utils.ensure_dependencies_clean(ConfigFile.load)
      
      if !dependencies_clean
        Console.log_error("You must commit changes to your dependencies before you can commit this repo")
        exit 1
      end
      
      LockFile.update
      Console.log_info("Updated and staged lock file with current HEAD revisions for all dependencies")
      
      exit 0 # Success!
    rescue StandardError => e
      Console.log_error("Pre-commit hook failed to execute! #{e.message}")
      exit 1 # Something went wrong!
    end
  end
end
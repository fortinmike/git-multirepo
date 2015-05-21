require "multirepo/files/config-file"
require "multirepo/files/tracking-files"
require "multirepo/utility/utils"
require "multirepo/utility/console"

module MultiRepo
  class PreCommitHook
    def self.run
      Config.instance.running_git_hook = true
      
      Console.log_step("Performing pre-commit operations...")
      
      dependencies_clean = Utils.ensure_dependencies_clean(ConfigFile.new(".").load_entries)
      
      if !dependencies_clean
        Console.log_error("You must commit changes to your dependencies before you can commit this repo")
        exit 1
      end
      
      tracking_files = TrackingFiles.new(".")
      tracking_files.update
      tracking_files.stage
      
      Console.log_info("Updated and staged tracking files")
      
      exit 0 # Success!
    rescue MultiRepoException => e
      Console.log_error("Can't perform commit. Please review the following:\n#{e.message}")
    rescue StandardError => e
      Console.log_error("Pre-commit hook failed to execute! #{e.message}")
      exit 1 # Something went wrong!
    end
  end
end
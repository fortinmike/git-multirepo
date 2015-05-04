require "multirepo/files/config-file"
require "multirepo/files/tracking-files"
require "multirepo/utility/utils"
require "multirepo/utility/console"

module MultiRepo
  class PostCommitHook
    def self.run
      Config.instance.running_git_hook = true
      
      Console.log_step("Performing post-commit operations...")
      
      # Works around bug #91565510 (https://www.pivotaltracker.com/story/show/91565510)
      TrackingFiles.stage
      Console.log_info("Cleaned-up staging area")
      
      exit 0 # Success!
    rescue StandardError => e
      Console.log_error("Post-commit hook failed to execute! #{e.message}")
      exit 1 # Something went wrong!
    end
  end
end
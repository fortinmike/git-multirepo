require "multirepo/files/lock-file"
require "multirepo/utility/console"

module MultiRepo
  class PostMergeHook
    def self.run
      Config.instance.running_git_hook = true
      
      LockFile.update
      Console.log_info("Updated the lock file with current HEAD revisions for all dependencies")
      
      LockFile.commit("Automatic post-merge multirepo lock file update")
      Console.log_info("Committed the updated lock file")
      
      exit 0 # Success!
    end
  end
end
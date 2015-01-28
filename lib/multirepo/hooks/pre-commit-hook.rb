require "multirepo/files/config-file"
require "multirepo/files/lock-file"
require "multirepo/utility/utils"
require "multirepo/utility/console"

module MultiRepo
  class PreCommitHook
    def self.run
      entries =  ConfigFile.load
      uncommitted = Utils.check_for_uncommitted_changes(entries)
      
      if uncommitted
        Console.log_error("You must commit changes to your dependencies before you can commit the main repo")
        exit 1
      end
      
      LockFile.update
      Console.log_info("Updated and staged lock file with current HEAD revisions for all dependencies")
      
      exit 0 # Success!
    end
  end
end
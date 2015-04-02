require "multirepo/files/config-file"
require "multirepo/files/lock-file"
require "multirepo/utility/utils"
require "multirepo/utility/console"

module MultiRepo
  class PrepareCommitMsgHook
    def self.run(argv)
      Config.instance.running_git_hook = true
      
      case argv[1]
      when "merge"; pre_merge
      else; pre_commit
      end
      
      exit 0 # Success!
    end
    
    def self.pre_commit
      ensure_dependencies_clean
      update_lock_file
    end
    
    def self.pre_merge
      ensure_dependencies_clean
    end
    
    def self.ensure_dependencies_clean
      dependencies_clean = Utils.ensure_dependencies_clean(ConfigFile.load)
      if !dependencies_clean
        Console.log_error("multirepo: You must commit changes to your dependencies before you can commit this repo")
        exit 1
      end
    end
    
    def self.update_lock_file
      LockFile.update
      Console.log_info("multirepo: Updated and staged lock file with current HEAD revisions for all dependencies")
    end
  end
end
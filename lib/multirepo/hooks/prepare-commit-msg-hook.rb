require "multirepo/files/config-file"
require "multirepo/files/lock-file"
require "multirepo/utility/utils"
require "multirepo/utility/console"

module MultiRepo
  class PrepareCommitMsgHook
    def self.run(argv)
      Config.instance.running_git_hook = true
      
      pre_merge if argv[1] == "merge"
      
      exit 0 # Success!
    end
    
    def self.pre_merge
      Console.log_step("multirepo: Performing pre-merge operations...")
      ensure_dependencies_clean
    end
    
    def self.ensure_dependencies_clean
      unless Utils.ensure_dependencies_clean(ConfigFile.load)
        Console.log_error("multirepo: You must commit changes to your dependencies before you can commit this repo")
        exit 1
      end
    end
  end
end
require "multirepo/files/config-file"
require "multirepo/files/lock-file"
require "multirepo/utility/utils"
require "multirepo/utility/console"

module MultiRepo
  class PreMergeHook
    def self.run
      Config.instance.running_git_hook = true
      
      dependencies_clean = Utils.ensure_dependencies_clean(ConfigFile.load)
      
      if !dependencies_clean
        Console.log_error("multirepo: You must commit changes to your dependencies before you can merge this repo")
        exit 1
      end
      
      exit 0 # Success!
    end
  end
end
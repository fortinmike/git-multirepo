require "claide"

require "info"
require "multirepo/multirepo-exception"
require "multirepo/config"

module MultiRepo
  class Command < CLAide::Command
    self.abstract_command = true
    self.command = "multi"
    self.version = VERSION
    self.description = DESCRIPTION
    
    def initialize(argv)
      Config.instance.verbose = argv.flag?("verbose") ? true : false
      super
    end
    
    def validate_in_work_tree
      raise MultiRepoException, "Not a git repository" unless Git.is_inside_git_repo(".")
    end
        
    def install_pre_commit_hook(repo_path = nil)
      Utils.install_pre_commit_hook(repo_path)
      Console.log_substep("Installed pre-commit hook")
    end
    
    def update_lock_file
      LockFile.update
      Console.log_substep("Updated and staged lock file with current HEAD revisions for all dependencies")
    end

    def ensure_multirepo_initialized
      raise MultiRepoException, "multirepo is not initialized in this repository." unless ConfigFile.exists?
    end
  end
end
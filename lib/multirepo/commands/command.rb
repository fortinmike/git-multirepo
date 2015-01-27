require "claide"
require "info"

module MultiRepo
  class Command < CLAide::Command
    self.abstract_command = true
    self.command = "multi"
    self.version = VERSION
    self.description = DESCRIPTION
    
    def run
      validate_in_work_tree
    end
    
    def validate_in_work_tree
      raise "Not a git repository" unless Git.is_inside_git_repo(".")
    end
    
    def load_entries
      @entries = ConfigFile.load_entries
      if !@entries then raise "Failed to load entries from .multirepo file" end
    end
    
    def install_pre_commit_hook
      Utils.install_pre_commit_hook
      Console.log_substep("Installed pre-commit hook")
    end
    
    def update_lock_file
      LockFile.update
      Console.log_substep("Updated and staged lock file with current HEAD revisions for all dependencies")
    end

    def ensure_multirepo_initialized
      raise "multirepo is not initialized in this repository. Please run \"multi init\"" unless ConfigFile.exists?
    end
  end
end
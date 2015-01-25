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
      if !Git.is_inside_git_repo(".") then raise "Not a git repository" end
    end
    
    def load_entries
      @entries = ConfigFile.load_entries
      if !@entries then raise "Failed to load entries from .multirepo file" end
    end
    
    def install_pre_commit_hook
      MultiRepo.install_pre_commit_hook
      Console.log_substep("Installed pre-commit hook")
    end
    
    def update_lock_file
      LockFile.update
      Console.log_substep("Updated lock file with current HEAD revisions for all dependencies")
    end
  end
end
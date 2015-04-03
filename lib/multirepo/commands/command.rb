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
    
    def install_hooks_in_multirepo_enabled_dependencies
      # Install the local git hooks in dependency repos
      # if they are themselves tracked with multirepo
      ConfigFile.load.each do |entry|
        if Utils.is_multirepo_enabled(entry.repo.path)
          install_hooks(entry.repo.path)
          Console.log_substep("Installed hooks in multirepo-enabled dependency '#{entry.repo.path}'")
        end
      end
    end
    
    def install_hooks(path = nil)
      actual_path = path || "."
      Utils.install_hook("pre-commit", actual_path)
      Utils.install_hook("prepare-commit-msg", actual_path)
      Utils.install_hook("post-merge", actual_path)
    end
    
    def uninstall_hooks
      File.delete(".git/hooks/pre-commit")
      File.delete(".git/hooks/prepare-commit-msg")
      File.delete(".git/hooks/post-merge")
    end
    
    def ensure_multirepo_initialized
      raise MultiRepoException, "multirepo is not initialized in this repository." unless Utils.is_multirepo_enabled(".")
    end
  end
end
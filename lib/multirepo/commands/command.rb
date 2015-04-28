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
      Config.instance.git_executable = argv.option("git-exe", "git")
      super
    end

    def validate!
      path = Config.instance.git_executable
      is_git_exe = path =~ /.*(git)|(git.exe)$/
      file_exists = path == "git" || File.exists?(path)
      help! "Invalid git executable '#{path}'" unless is_git_exe && file_exists
    end
    
    def validate_in_work_tree
      raise MultiRepoException, "Not a git repository" unless Git.is_inside_git_repo(".")
    end
    
    def install_hooks_in_multirepo_enabled_dependencies
      ConfigFile.load.each do |entry|
        if Utils.is_multirepo_enabled(entry.repo.path)
          install_hooks(entry.repo.path)
          Console.log_substep("Installed hooks in multirepo-enabled dependency '#{entry.repo.path}'")
        end
      end
    end

    def update_gitattributes_in_multirepo_enabled_dependencies
      ConfigFile.load.each do |entry|
        if Utils.is_multirepo_enabled(entry.repo.path)
          update_gitattributes(entry.repo.path)
          Console.log_substep("Updated .gitattributes in multirepo-enabled dependency '#{entry.repo.path}'")
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

    def update_gitattributes(path = nil)
      actual_path = path || "."
      gitattributes_file = File.join(actual_path, ".gitattributes")
      add_line_if_missing(gitattributes_file, ".multirepo.lock merge=ours")
    end

    def add_line_if_missing(path, line)
      unless File.exists?(path)
        File.open(path, 'w') { |f| f.puts(line) }
      else
        line_exists = File.readlines(path).grep(/#{line}/).any?
        File.open(path, 'a') { |f| f.puts(line) } unless line_exists
      end
    end
    
    def ensure_multirepo_enabled
      raise MultiRepoException, "multirepo is not initialized in this repository." unless Utils.is_multirepo_enabled(".")
    end

    def ensure_multirepo_tracked
      raise MultiRepoException, "This revision is not tracked by multirepo." unless Utils.is_multirepo_tracked(".")
    end
  end
end
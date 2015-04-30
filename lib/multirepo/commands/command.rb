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
    
    def install_hooks(path)
      actual_path = path || "."
      Utils.install_hook("pre-commit", actual_path)
    end
    
    def uninstall_hooks
      File.delete(".git/hooks/pre-commit")
    end
    
    def update_gitconfig(path)
      actual_path = path || "."
      resource_file = Utils.path_for_resource(".gitconfig")
      target_file = File.join(actual_path, '.git/config')
      
      template = File.read(resource_file)
      first_template_line = template.lines.first
      
      Utils.append_if_missing(target_file, Regexp.new(Regexp.quote(first_template_line)), template)
    end
    
    def multirepo_enabled_dependencies
      ConfigFile.load.select { |e| Utils.is_multirepo_enabled(e.repo.path) }
    end
    
    def ensure_multirepo_enabled
      raise MultiRepoException, "multirepo is not initialized in this repository." unless Utils.is_multirepo_enabled(".")
    end

    def ensure_multirepo_tracked
      raise MultiRepoException, "This revision is not tracked by multirepo." unless Utils.is_multirepo_tracked(".")
    end
  end
end
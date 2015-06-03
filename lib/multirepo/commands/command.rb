require "claide"

require "info"
require "multirepo/multirepo-exception"
require "multirepo/config"
require "multirepo/files/config-file"
require "multirepo/files/lock-file"

module MultiRepo
  class Command < CLAide::Command
    self.abstract_command = true
    self.command = "multi"
    self.version = VERSION
    self.description = DESCRIPTION
    
    def self.report_error(exception)
      if exception.instance_of?(MultiRepoException)
        Console.log_error(exception.message)
        exit 1
      end
      raise exception
    end
    
    def initialize(argv)
      @argv = argv
      Config.instance.verbose |= argv.flag?("verbose") ? true : false
      Config.instance.git_executable = argv.option("git-exe", "git")
      super
    end
    
    def run
      help!
    end

    def validate!
      super
      path = Config.instance.git_executable
      is_git_exe = path =~ /.*(git)|(git.exe)$/
      file_exists = path == "git" || File.exists?(path)
      help! "Invalid git executable '#{path}'" unless is_git_exe && file_exists
    end
    
    def install_hooks(path)
      actual_path = path || "."
      Utils.install_hook("pre-commit", actual_path)
      Utils.install_hook("post-commit", actual_path)
    end
    
    def uninstall_hooks
      FileUtils.rm_f(".git/hooks/pre-commit")
      FileUtils.rm_f(".git/hooks/post-commit")
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
      ConfigFile.new(".").load_entries.select { |e| Utils.is_multirepo_enabled(e.repo.path) }
    end

    def validate_only_one_flag(*flags)
      flags.reduce(0) { |count, flag| count += 1 if flag; count } <= 1
    end
    
    def ensure_in_work_tree
      repo = Repo.new(".")
      raise MultiRepoException, "Not a git repository" unless repo.exists?
      raise MultiRepoException, "HEAD is unborn (you must perform at least one commit)" unless repo.head_born?
    end
    
    def ensure_multirepo_enabled
      raise MultiRepoException, "multirepo is not initialized in this repository." unless Utils.is_multirepo_enabled(".")
    end

    def ensure_multirepo_tracked
      raise MultiRepoException, "Revision is not tracked by multirepo." unless Utils.is_multirepo_tracked(".")
      
      lock_file_valid = LockFile.new(".").validate!
      raise MultiRepoException, "Revision is multirepo-enabled but contains a corrupted lock file!" unless lock_file_valid
    end
  end
end
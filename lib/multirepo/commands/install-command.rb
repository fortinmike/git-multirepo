require "terminal-table"

require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"
require "multirepo/logic/performer"
require "multirepo/commands/checkout-command"

module MultiRepo
  class InstallCommand < Command
    self.command = "install"
    self.summary = "Clones and checks out dependencies as defined in the version-controlled multirepo metadata files and installs git-multirepo's local git hooks."
    
    def self.options
      [
        ['[--hooks]', 'Only install local git hooks.'],
        ['[--ci]', 'For use in a continuous integration context (such as on a CI build server or agent).']
      ].concat(super)
    end
    
    def initialize(argv)
      @hooks = argv.flag?("hooks")
      @ci = argv.flag?("ci")
      super
    end
    
    def validate!
      super
      unless validate_only_one_flag(@hooks, @ci)
        help! "You can't provide more than one operation modifier (--hooks, --ci, etc.)"
      end
    end
        
    def run
      ensure_in_work_tree unless @ci
      ensure_multirepo_tracked
      
      if @hooks
        Console.log_step("Installing hooks in main repo and all dependencies...")
        install_hooks_step
      else
        Console.log_step("Installing dependencies...")
        log_ci_info if @ci
        full_install
      end
      
      Console.log_step("Done!")
    end
    
    def log_ci_info
      Console.log_warning("Performing continuous-integration-aware install")
      
      main_repo = Repo.new(".")
      main_repo_branch = main_repo.current_branch
      meta_file = MetaFile.new(".").load

      table = Terminal::Table.new do |t|
        t.title = "Revision Info"
        t.add_row ["git-multirepo version", meta_file.version]
        t.add_separator
        t.add_row ["Main Repo", commit_info(main_repo.head.commit_id, (main_repo_branch.name rescue nil))]
        t.add_separator
        LockFile.new(".").load_entries.each do |lock_entry|
          branch_name = lock_entry.branch
          t.add_row [lock_entry.name, commit_info(lock_entry.head, branch_name)]
        end
      end
      puts table
    end

    def commit_info(commit_id, branch_name)
      commit_id + (branch_name ? " (on branch #{branch_name})" : "")
    end
    
    def full_install
      install_dependencies_step
      install_hooks_step unless @ci
      update_gitconfigs_step unless @ci
    end
    
    def install_dependencies_step
      # Read config entries as-is on disk, without prior checkout
      config_entries = ConfigFile.new(".").load_entries
      Console.log_substep("Installing #{config_entries.count} dependencies...");
      
      # Clone or fetch all configured dependencies to make sure nothing is missing locally
      Performer.dependencies.each { |d| clone_or_fetch(d) }
      
      # Checkout the appropriate branches as specified in the lock file
      checkout_command = CheckoutCommand.new(CLAide::ARGV.new([]))
      mode = @ci ? RevisionSelectionMode::AS_LOCK : RevisionSelectionMode::LATEST
      checkout_command.dependencies_checkout_step(mode)
    end
    
    def install_hooks_step
      perform_in_main_repo_and_dependencies("Installed git hooks") { |repo| install_hooks(repo) }
    end
    
    def update_gitconfigs_step
      perform_in_main_repo_and_dependencies("Updated .git/config file") { |repo| update_gitconfig(repo) }
    end
    
    def perform_in_main_repo_and_dependencies(message_prefix, &operation)
      operation.call(".")
      Console.log_substep("#{message_prefix} in main repo")
      
      multirepo_enabled_dependencies.each do |config_entry|
        operation.call(config_entry.repo.path)
        Console.log_substep("#{message_prefix} in multirepo-enabled dependency '#{config_entry.repo.path}'")
      end
    end
    
    # Repo operations
    
    def clone_or_fetch(dependency)
      if dependency.config_entry.repo.exists?
        check_repo_validity(dependency)
        
        Console.log_substep("Working copy '#{dependency.config_entry.repo.path}' already exists, fetching...")
        fetch_repo(dependency)
      else
        Console.log_substep("Cloning #{dependency.config_entry.url} into '#{dependency.config_entry.repo.path}'")
        clone_repo(dependency)
      end
    end
    
    def fetch_repo(dependency)
      unless dependency.config_entry.repo.fetch
        raise MultiRepoException, "Could not fetch from remote #{dependency.config_entry.repo.remote('origin').url}"
      end
    end
    
    def clone_repo(dependency)
      unless dependency.config_entry.repo.clone(dependency.config_entry.url, dependency.lock_entry.branch)
        raise MultiRepoException, "Could not clone remote #{dependency.config_entry.url} with branch #{dependency.config_entry.branch}"
      end
    end
    
    # Validation
    
    def check_repo_validity(dependency)
      unless dependency.config_entry.repo.remote("origin").url == dependency.config_entry.url
        raise MultiRepoException, "'#{dependency.config_entry.path}' origin URL (#{dependency.config_entry.repo.remote('origin').url}) does not match entry (#{dependency.config_entry.url})!"
      end
    end
  end
end
require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/files/config-file"
require "multirepo/files/lock-file"
require "multirepo/files/tracking-files"
require "multirepo/commands/command"

module MultiRepo
  class InitCommand < Command
    self.command = "init"
    self.summary = "Initialize the current repository as a multirepo project."
    
    def self.options
      [['[--extras]', 'Keep the current .multirepo config file as-is and initialize everything else.']].concat(super)
    end
    
    def initialize(argv)
      @only_extras = argv.flag?("extras")
      super
    end
    
    def run
      super
      ensure_in_work_tree
      
      if @only_extras
        ensure_multirepo_enabled
        Console.log_step("Initializing extras...")
        initialize_extras_step
      else
        Console.log_step("Initializing multirepo...")
        full_initialize_step
      end
      
      Console.log_step("Done!")
    end
    
    def full_initialize_step
      if ConfigFile.new(".").exists?
        reinitialize = Console.ask_yes_no(".multirepo file already exists. Reinitialize?")
        raise MultiRepoException, "Initialization aborted" unless reinitialize
      end
      
      unless add_sibling_repos_step
        raise MultiRepoException, "There are no sibling repositories to track as dependencies. Initialization aborted."
      end

      initialize_extras_step
    end
    
    def add_sibling_repos_step
      sibling_repos = Utils.sibling_repos
      return false unless sibling_repos.any?

      Console.log_substep("Creating new multirepo config...")
      
      valid_repos = find_valid_repos(sibling_repos)
      entries = create_entries(valid_repos)
      
      raise MultiRepoException, "No sibling repositories were added as dependencies; aborting." unless entries.any?
      
      ConfigFile.new(".").save_entries(entries)
      return true
    end
    
    def initialize_extras_step
      install_hooks_step
      update_gitattributes_step
      update_gitconfig_step
    end
    
    def install_hooks_step
      install_hooks(".")
      Console.log_substep("Installed git hooks")
    end
    
    def update_gitattributes_step
      TrackingFiles.new(".").files.each do |f|
        filename = f.filename
        regex_escaped_filename = Regexp.quote(filename)
        Utils.append_if_missing("./.gitattributes", /^#{regex_escaped_filename} .*/, "#{filename} merge=ours")
      end
      Console.log_substep("Updated .gitattributes file")
    end
    
    def update_gitconfig_step
      update_gitconfig(".")
      Console.log_substep("Updated .git/config file")
    end
    
    def find_valid_repos(repos)
      repos.select do |repo|
        next true if repo.head_born?
        Console.log_warning("Ignoring repo '#{repo.path}' because its HEAD is unborn. You must perform at least one commit.")
      end
    end
    
    def create_entries(repos)
      entries = []
      repos.each do |repo|
        origin_url = repo.remote('origin').url
        current_branch = repo.current_branch
        
        if Console.ask_yes_no("Do you want to add '#{repo.path}' as a dependency?\n  [origin: #{origin_url || "NONE"}, branch: #{current_branch}]")
          raise MultiRepoException, "Repo 'origin' remote url is not set; aborting." unless origin_url
          entries.push(ConfigEntry.new(repo))
          Console.log_substep("Added the repository '#{repo.path}' to the .multirepo file")
        end
      end
      return entries
    end
    
    def check_repo_exists
      raise MultiRepoException, "There is no folder at path '#{@repo.path}'" unless Dir.exists?(@repo.path)
      raise MultiRepoException, "'#{@repo.path}' is not a repository" unless @repo.exists?
    end
  end
end
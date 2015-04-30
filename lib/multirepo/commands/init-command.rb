require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/files/config-file"
require "multirepo/files/lock-file"
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
      validate_in_work_tree
      
      if @only_extras
        Console.log_step("Initializing extras...")
        initialize_extras_step
      else
        Console.log_step("Initializing multirepo...")
        full_initialize_step
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def full_initialize_step
      if ConfigFile.exists?
        reinitialize = Console.ask_yes_no(".multirepo file already exists. Reinitialize?")
        raise MultiRepoException, "Initialization aborted" unless reinitialize
      end
      
      Console.log_substep("Creating new multirepo config...")
      
      add_sibling_repos_step
      initialize_extras_step
    end
    
    def add_sibling_repos_step
      sibling_repos = Utils.sibling_repos
      
      if sibling_repos.any?
        entries = []
        sibling_repos.each do |repo|
          origin_desc = repo.remote('origin').url || "[none]"
          current_branch = repo.current_branch
          if Console.ask_yes_no("Do you want to add '#{repo.path}' as a dependency?\n  [origin: '#{origin_desc}', branch: #{current_branch}]")
            entries.push(ConfigEntry.new(repo))
            Console.log_substep("Added the repository '#{repo.path}' to the .multirepo file")
          end
        end
        
        ConfigFile.save(entries)
        ConfigFile.stage
      else
        Console.log_info("There are no sibling repositories to add")
      end
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
      Utils.append_if_missing("./.gitattributes", ".multirepo.lock", ".multirepo.lock merge=ours")
      Console.log_substep("Updated .gitattributes file")
    end
    
    def update_gitconfig_step
      update_gitconfig(".")
      Console.log_substep("Updated .git/config file")
    end
    
    def check_repo_exists
      if !Dir.exists?(@repo.path) then raise MultiRepoException, "There is no folder at path '#{@repo.path}'" end
      if !@repo.exists? then raise MultiRepoException, "'#{@repo.path}' is not a repository" end
    end
  end
end
require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/files/config-file"
require "multirepo/files/lock-file"
require "multirepo/commands/command"

module MultiRepo
  class InitCommand < Command
    self.command = "init"
    self.summary = "Initialize the current repository as a multirepo project."
    
    def run
      validate_in_work_tree
      Console.log_step("Initializing new multirepo config...")
      
      if ConfigFile.exists?
        return unless Console.ask_yes_no(".multirepo file already exists. Reinitialize?")
      end
      
      sibling_repos = Utils.sibling_repos
      
      if sibling_repos.any?
        entries = []
        sibling_repos.each do |repo|
          if Console.ask_yes_no("Do you want to add '#{repo.path}' (#{repo.remote('origin').url} #{repo.current_branch}) as a dependency?")
            entries.push(ConfigEntry.new(repo))
            Console.log_substep("Added the repository '#{repo.path}' to the .multirepo file")
          end
        end
        
        ConfigFile.save(entries)
        ConfigFile.stage
      
        dependencies_clean = Utils.ensure_dependencies_clean(entries)
        raise MultiRepoException, "Can't finish initialization!" unless dependencies_clean
        
        self.update_lock_file
      else
        Console.log_info("There are no sibling repositories to add")
      end
      
      install_hooks
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def check_repo_exists
      if !Dir.exists?(@repo.path) then raise MultiRepoException, "There is no folder at path '#{@repo.path}'" end
      if !@repo.exists? then raise MultiRepoException, "'#{@repo.path}' is not a repository" end
    end
  end
end
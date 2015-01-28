require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/files/config-file"
require "multirepo/files/lock-file"

module MultiRepo
  class Init < Command
    self.command = "init"
    self.summary = "Initialize the current repo as a multirepo project."
    
    def run
      super
      Console.log_step("Initializing new multirepo config...")
      
      if ConfigFile.exists?
        return unless Console.ask_yes_no(".multirepo file already exists. Reinitialize?")
        ConfigFile.create
        Console.log_substep("Created .multirepo file")
      end
      
      sibling_repos = Utils.sibling_repos
      
      if sibling_repos.any?
        added_entries = []
        sibling_repos.each do |repo|
          if Console.ask_yes_no("Do you want to add #{repo.path} (#{repo.remote('origin').url} #{repo.current_branch}) as a dependency?")
            entry = ConfigEntry.new(repo)
            added_entries.push(entry)
            ConfigFile.add_entry(entry)
            Console.log_substep("Added the repository #{entry.repo.path} to the .multirepo file")
          end
        end
        
        ConfigFile.stage
      
        uncommitted = Utils.check_for_uncommitted_changes(added_entries)
        raise MultiRepoException, "Can't finish initialization!" if uncommitted
        
        self.update_lock_file
      else
        Console.log_info("There are no sibling repositories to add")
      end
      
      self.install_pre_commit_hook
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def check_repo_exists
      if !Dir.exists?(@repo.path) then raise MultiRepoException, "There is no folder at path #{@repo.path}" end
      if !@repo.exists? then raise MultiRepoException, "#{@repo.path} is not a repository" end
    end
  end
end
require "multirepo"
require "multirepo/utility/console"
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
      
      sibling_repos = MultiRepo.sibling_repos
      
      if sibling_repos.any?
        added_entries = []
        sibling_repos.each do |repo|
          if Console.ask_yes_no("Do you want to add #{repo.working_copy} (#{repo.remote('origin').url} #{repo.current_branch}) as a dependency?")
            entry = ConfigEntry.new(repo)
            added_entries.push(entry)
            ConfigFile.add_entry(entry)
            Console.log_substep("Added the repository #{entry.repo.working_copy} to the .multirepo file")
          end
        end
      
        ensure_no_uncommited_changes(added_entries)
        self.update_lock_file
      else
        Console.log_info("There are no sibling repositories to add")
      end
      
      self.install_pre_commit_hook
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
    
    def ensure_no_uncommited_changes(entries)
      uncommited = false
      entries.each do |e|
        next unless e.repo.exists?
        if e.repo.has_uncommited_changes
          Console.log_warning("Repository #{e.repo.working_copy} has uncommited changes")
          uncommited = true
        end
      end
      raise "Can't finish initialization!" if uncommited
    end
    
    def check_repo_exists
      if !Dir.exists?(@repo.working_copy) then raise "There is no folder at path #{@repo.working_copy}" end
      if !@repo.exists? then raise "#{@repo.working_copy} is not a repository" end
    end
  end
end
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
      
      Console.log_step("Initializing multirepo...")
      
      unless ConfigFile.exists?
        ConfigFile.create
        Console.log_substep("Created .multirepo file")
      else
        Console.log_info(".multirepo file already exists")
      end
      
      entries = []
      MultiRepo.sibling_repos.each do |repo|
        if Console.ask_yes_no("Do you want to add #{repo.working_copy} (#{repo.remote('origin').url} #{repo.current_branch}) as a dependency?")
          entry = ConfigEntry.new(repo)
          entries.push(entry)
          if entry.exists?
            Console.log_info("There is already an entry for #{entry.folder_name} in the .multirepo file")
          else
            entry.add
            Console.log_substep("Added the repository #{entry.repo.working_copy} to the .multirepo file")
          end
        end
      end
      
      ensure_no_uncommited_changes(entries)
      self.install_pre_commit_hook
      self.update_lock_file
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
    
    def ensure_no_uncommited_changes(entries)
      uncommited = false
      entries.each do |e|
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
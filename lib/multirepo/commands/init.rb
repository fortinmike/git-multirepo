require "claide"

require "multirepo"
require "multirepo/utility/console"
require "multirepo/config"

module MultiRepo
  class Init < Command
    self.command = "init"
    self.summary = "Initialize the current repo as a multirepo project."
    
    def run
      super
      
      Console.log_step("Initializing multirepo...")
      
      unless Config.exists?
        Config.create
        Console.log_substep("Created .multirepo file")
      else
        Console.log_info(".multirepo file already exists")
      end
      
      sibling_repos.each do |repo|
        if Console.ask_yes_no("Do you want to add #{repo.working_copy} (#{repo.remote('origin').url} #{repo.current_branch}) as a dependency?")
          entry = Entry.new(repo)
          if entry.exists?
            Console.log_info("There is already an entry for #{entry.folder_name} in the .multirepo file")
          else
            entry.add
            Console.log_substep("Added the repository #{entry.repo.working_copy} to the .multirepo file")
          end
        end
      end
      
      MultiRepo.install_pre_commit_hook
      Console.log_substep("Installed pre-commit hook")
              
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
    
    def sibling_repos
      sibling_directories = Dir['../*/']
      sibling_repos = sibling_directories.map{ |d| Repo.new(d) }.select{ |r| r.exists? }
      sibling_repos.delete_if{ |r| Pathname.new(r.working_copy).realpath == Pathname.new(".").realpath }
    end
    
    def check_repo_exists
      if !Dir.exists?(@repo.working_copy) then raise "There is no folder at path #{@repo.working_copy}" end
      if !@repo.exists? then raise "#{@repo.working_copy} is not a repository" end
    end
  end
end
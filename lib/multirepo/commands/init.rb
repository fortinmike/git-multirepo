require "claide"

require "multirepo/utility/console"
require "multirepo/config"

module MultiRepo
  class Init < Command
    self.command = "init"
    self.summary = "Initialize the current repo as a multirepo project."
    
    def run
      super
      Config.create unless Config.exists?
      
      Console.log_step("Initializing multirepo...")
      
      sibling_repos.each do |repo|
        if Console.ask_yes_no("Do you want to add #{repo.working_copy} as a dependency?")
          Config.add(repo)
        end
      end
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
    
    def sibling_repos
      sibling_directories = Dir['../*/']
      sibling_directories.map{ |d| Repo.new(d) }.select{ |r| r.exists? }
    end
    
    def check_repo_exists
      if !Dir.exists?(@repo.working_copy) then raise "There is no folder at path #{@repo.working_copy}" end
      if !@repo.exists? then raise "#{@repo.working_copy} is not a repository" end
    end
  end
end
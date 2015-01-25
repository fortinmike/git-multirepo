require "claide"

require "multirepo/utility/console"
require "multirepo/config"

module MultiRepo
  class Add < Command
    self.command = "add"
    self.summary = "Add a repository to the .multirepo file."
    
    def initialize(argv)
      @repo = Repo.new("../#{argv.shift_argument}")
      super
    end
    
    def run
      super
      check_repo_exists
      unless Config.exists?
        Config.create
        Console.log_substep("Created missing .multirepo file")
      end
      
      entry = Entry.new(@repo)
      if entry.exists?
        Console.log_info("There is already an entry for #{entry.folder_name} in the .multirepo file")
      else
        entry.add
        Console.log_info("Added the repository #{entry.repo.working_copy} to the .multirepo file")
      end
    rescue Exception => e
      Console.log_error(e.message)
    end
    
    def check_repo_exists
      if !Dir.exists?(@repo.working_copy) then raise "There is no folder at path #{@repo.working_copy}" end
      if !@repo.exists? then raise "#{@repo.working_copy} is not a repository" end
    end
  end
end
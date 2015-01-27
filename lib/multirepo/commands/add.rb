require "multirepo/utility/console"
require "multirepo/files/config-file"

module MultiRepo
  class Add < Command
    self.command = "add"
    self.summary = "Add a dependency repository to the .multirepo file."
    
    def initialize(argv)
      @repo = Repo.new("../#{argv.shift_argument}")
      super
    end
    
    def run
      super
      ensure_multirepo_initialized
      ensure_dependency_repo_exists

      unless ConfigFile.exists?
        ConfigFile.create
        Console.log_substep("Created missing .multirepo file")
      end
      
      entry = ConfigEntry.new(@repo)
      if ConfigFile.entry_exists?(entry)
        Console.log_info("There is already an entry for #{entry.folder_name} in the .multirepo file")
      else
        ConfigFile.add_entry(entry)
        ConfigFile.stage
        Console.log_substep("Added the repository #{entry.repo.working_copy} to the .multirepo file")
      end
    rescue Exception => e
      Console.log_error(e.message)
    end
    
    def ensure_dependency_repo_exists
      if !Dir.exists?(@repo.working_copy) then raise "There is no folder at path #{@repo.working_copy}" end
      if !@repo.exists? then raise "#{@repo.working_copy} is not a repository" end
    end
  end
end
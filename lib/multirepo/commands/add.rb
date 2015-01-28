require "multirepo/utility/console"
require "multirepo/files/config-file"

module MultiRepo
  class Add < Command
    self.command = "add"
    self.summary = "Add a dependency repository to the .multirepo file."
    
    def initialize(argv)
      @path = argv.shift_argument
      super
    end
    
    def validate!
      super
      help! "You must provide a repo path to add as a dependency" unless @path
    end
    
    def run
      super
      ensure_multirepo_initialized
      ensure_dependency_repo_exists

      unless ConfigFile.exists?
        ConfigFile.create
        Console.log_substep("Created missing .multirepo file")
      end
      
      repo = Repo.new(@path)
      entry = ConfigEntry.new(repo)
      if ConfigFile.entry_exists?(entry)
        Console.log_info("There is already an entry for #{entry.path} in the .multirepo file")
      else
        ConfigFile.add_entry(entry)
        ConfigFile.stage
        Console.log_substep("Added the repository #{entry.path} to the .multirepo file")
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def ensure_dependency_repo_exists
      if !Dir.exists?(@repo.path) then raise MultiRepoException, "There is no folder at path #{@path}" end
      if !@repo.exists? then raise MultiRepoException, "#{@path} is not a repository" end
    end
  end
end
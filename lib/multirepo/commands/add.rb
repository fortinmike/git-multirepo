require "multirepo/utility/console"
require "multirepo/files/config-file"

module MultiRepo
  class Add < Command
    self.command = "add"
    self.summary = "Add a dependency to the .multirepo file."
    
    def initialize(argv)
      @path = argv.shift_argument
      super
    end
    
    def validate!
      super
      help! "You must provide a repository to add as a dependency" unless @path
    end
    
    def run
      super
      ensure_multirepo_initialized
      ensure_repo_exists
      
      entry = ConfigEntry.new(Repo.new(@path))
      if ConfigFile.entry_exists?(entry)
        Console.log_info("There is already an entry for #{@path} in the .multirepo file")
      else
        ConfigFile.add_entry(entry)
        ConfigFile.stage
        Console.log_step("Added #{@path} to the .multirepo file")
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def ensure_repo_exists
      raise MultiRepoException, "There is no folder at path #{@path}" unless Dir.exists?(@path)
      raise MultiRepoException, "#{@path} is not a repository" unless Repo.new(@path).exists?
    end
  end
end
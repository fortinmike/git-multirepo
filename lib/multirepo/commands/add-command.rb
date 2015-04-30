require "multirepo/utility/console"
require "multirepo/files/config-file"

module MultiRepo
  class AddCommand < Command
    self.command = "add"
    self.summary = "Track an additional dependency with multirepo."
    
    def self.options
      [['<path>', 'The relative path to the new dependency (e.g. ../MyNewDependency)']].concat(super)
    end
    
    def initialize(argv)
      @path = argv.shift_argument
      super
    end
    
    def validate!
      super
      help! "You must specify a repository to add as a dependency" unless @path
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      ensure_repo_valid
      
      entry = ConfigEntry.new(Repo.new(@path))
      if ConfigFile.entry_exists?(entry)
        Console.log_info("There is already an entry for '#{@path}' in the .multirepo file")
      else
        ConfigFile.add_entry(entry)
        Console.log_step("Added '#{@path}' to the .multirepo file")
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def ensure_repo_valid
      raise MultiRepoException, "The provided path is not a direct sibling of the main repository" unless validate_is_sibling_repo(@path)
      raise MultiRepoException, "There is no folder at path '#{@path}'" unless Dir.exists?(@path)
      raise MultiRepoException, "'#{@path}' is not a repository" unless Repo.new(@path).exists?
    end
    
    def validate_is_sibling_repo(path)
      parent_dir = File.expand_path("..")
      path = File.expand_path("..", path)
      return parent_dir == path
    end
  end
end
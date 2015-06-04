require "multirepo/utility/console"
require "multirepo/files/config-file"

module MultiRepo
  class RemoveCommand < Command
    self.command = "remove"
    self.summary = "Removes the specified dependency from multirepo."
    
    def self.options
      [
        ['<path>', 'The relative path to the dependency to remove (e.g. ../MyOldDependency).'],
        ['[--delete]', 'Delete the dependency on disk in addition to removing it from the multirepo config.']
      ].concat(super)
    end
    
    def initialize(argv)
      @path = argv.shift_argument
      @delete = argv.flag?("delete")
      super
    end
    
    def validate!
      super
      help! "You must specify a dependency repository to remove" unless @path
    end
    
    def run
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      repo = Repo.new(@path)
      entry = ConfigEntry.new(repo)
      
      config_file = ConfigFile.new(".")
      if config_file.entry_exists?(entry)
        config_file.remove_entry(entry)
        Console.log_step("Removed '#{@path}' from the .multirepo file")
        
        if @delete
          FileUtils.rm_rf(@path)
          Console.log_step("Deleted '#{@path}' from disk")
        end
      else
        fail MultiRepoException, "'#{@path}' isn't tracked by multirepo"
      end
    end
  end
end

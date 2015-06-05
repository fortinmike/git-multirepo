require "multirepo/files/config-file"
require "multirepo/files/lock-file"

require_relative "dependency"

module MultiRepo
  class Performer
    def self.perform_main_repo_checkout(main_repo, ref_name, message = nil)
      # Make sure the main repo is clean before attempting a checkout
      unless main_repo.clean?
        fail MultiRepoException, "Can't checkout #{ref_name} because the main repo contains uncommitted changes"
      end
      
      # Checkout the specified ref
      unless main_repo.checkout(ref_name)
        fail MultiRepoException, "Couldn't perform checkout of main repo #{ref_name}!"
      end
      
      Console.log_substep(message || "Checked out main repo #{ref_name}")
      
      # After checkout, make sure we're working with a multirepo-enabled ref
      unless Utils.multirepo_tracked?(".")
        fail MultiRepoException, "Revision #{ref_name} is not tracked by multirepo!"
      end
    end
    
    def self.dependencies
      config_entries = ConfigFile.new(".").load_entries
      lock_entries = LockFile.new(".").load_entries
      
      dependencies = build_dependencies(config_entries, lock_entries)
      dependency_ordered_nodes = Node.new(".").ordered_descendants
      
      return dependency_ordered_nodes.map do |node|
        dependencies.find { |d| d.config_entry.path == node.path }
      end
    end
    
    def self.build_dependencies(config_entries, lock_entries)
      lock_entries.map do |lock_entry|
        config_entry = config_entry_for_lock_entry(config_entries, lock_entry)
        
        dependency = Dependency.new
        dependency.config_entry = config_entry
        dependency.lock_entry = lock_entry
        
        next dependency
      end
    end
    
    def self.config_entry_for_lock_entry(config_entries, lock_entry)
      config_entries.find { |config_entry| config_entry.id == lock_entry.id }
    end
  end
end

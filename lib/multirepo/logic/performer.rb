require "ostruct"

require "multirepo/files/config-file"
require "multirepo/files/lock-file"

module MultiRepo
  class Performer
    def self.perform_main_repo_checkout(main_repo, ref_name)
      # Make sure the main repo is clean before attempting a checkout
      unless main_repo.is_clean?
        raise MultiRepoException, "Can't checkout #{ref_name} because the main repo contains uncommitted changes"
      end
      
      # Checkout the specified ref
      unless main_repo.checkout(ref_name)
        raise MultiRepoException, "Couldn't perform checkout of main repo #{ref_name}!"
      end
      
      Console.log_substep("Checked out main repo #{ref_name}")
      
      # After checkout, make sure we're working with a multirepo-enabled ref
      unless Utils.is_multirepo_tracked(".")
        raise MultiRepoException, "Revision #{ref_name} is not tracked by multirepo!"
      end
    end
    
    def self.perform_on_dependencies(&operation)
      config_entries = ConfigFile.new(".").load_entries
      lock_entries = LockFile.new(".").load_entries
      perform_on_dependencies_with_entries(config_entries, lock_entries, operation)
    end
    
    def self.perform_on_dependencies_with_entries(config_entries, lock_entries, &operation)
      config_lock_pairs = build_config_lock_pairs(config_entries, lock_entries)
      dependency_ordered_nodes = Node.new(".").ordered_descendants
      
      ordered_pairs = dependency_ordered_nodes.map do |node|
        pair = config_lock_pairs.find { |pair| pair.config_entry.path == node.path }
      end
      
      ordered_pairs.each { |pair| operation.call(pair.config_entry, pair.lock_entry) }
    end
    
    private
    
    def self.build_config_lock_pairs(config_entries, lock_entries)
      lock_entries.map do |lock_entry|
        config_entry = config_entry_for_lock_entry(config_entries, lock_entry)
        
        pair = OpenStruct.new
        pair.config_entry = config_entry
        pair.lock_entry = lock_entry
        
        next pair
      end
    end
    
    def self.config_entry_for_lock_entry(config_entries, lock_entry)
      config_entries.find { |config_entry| config_entry.id == lock_entry.id }
    end
  end
end
require "multirepo/files/config-file"
require "multirepo/files/lock-file"

module MultiRepo
  class Performer
    def self.perform_main_repo_checkout(main_repo, ref)
      # Make sure the main repo is clean before attempting a checkout
      unless main_repo.is_clean?
        raise MultiRepoException, "Can't checkout #{ref} because the main repo contains uncommitted changes"
      end
      
      # Checkout the specified ref
      unless main_repo.checkout(ref)
        raise MultiRepoException, "Couldn't perform checkout of main repo #{ref}!"
      end
      
      Console.log_substep("Checked out main repo #{ref}")
      
      # After checkout, make sure we're working with a multirepo-enabled ref
      unless Utils.is_multirepo_tracked(".")
        raise MultiRepoException, "Revision #{ref} is not tracked by multirepo!"
      end
    end
    
    def self.perform_on_dependencies(&operation)
      config_entries = ConfigFile.new(".").load_entries
      LockFile.new(".").load_entries.each do |lock_entry|
        # Find the config entry that matches the given lock entry
        config_entry = config_entries.select{ |config_entry| config_entry.id == lock_entry.id }.first
        operation.call(config_entry, lock_entry)
      end
    end
  end
end
require "multirepo/files/config-file"
require "multirepo/files/lock-file"

module MultiRepo
  class Performer
    def self.perform_on_dependencies(mode, ref, &operation)
      config_entries = ConfigFile.new(".").load_entries
      LockFile.new(".").load_entries.each do |lock_entry|
        # Find the config entry that matches the given lock entry
        config_entry = config_entries.select{ |config_entry| config_entry.id == lock_entry.id }.first
        
        # Find out the required dependency revision based on the checkout mode
        revision = RevisionSelector.ref_for_mode(mode, ref, lock_entry)
        
        operation.call(config_entry, lock_entry, revision)
      end
    end
  end
end
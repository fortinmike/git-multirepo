require "multirepo/files/config-file"
require "multirepo/files/lock-file"

module MultiRepo
  class Performer
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
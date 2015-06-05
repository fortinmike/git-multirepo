require "multirepo/utility/console"
require "multirepo/logic/performer"
require "multirepo/files/tracking-files"

module MultiRepo
  class UpdateCommand < Command
    self.command = "update"
    self.summary = "Force-updates the multirepo tracking files."
    
    def self.options
      [
        ['[--all]', 'Update the main repository and all dependencies.'],
        ['[--main]', 'Update the main repository.'],
        ['[--deps]', 'Update dependencies.'],
        ['[--force]', 'Update the tracking files even if dependencies contain uncommitted changes.'],
        ['[--commit]', 'Commit the tracking files after updating them.']
      ].concat(super)
    end
    
    def initialize(argv)
      @all = argv.flag?("all")
      @main_only = argv.flag?("main")
      @deps_only = argv.flag?("deps")
      @commit = argv.flag?("commit")
      @force = argv.flag?("force")
      super
    end

    def validate!
      super
      unless validate_only_one_flag(@all, @main_only, @deps_only)
        help! "You can't provide more than one operation modifier (--deps, --main, etc.)"
      end
    end

    def run
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      dependencies_clean = Utils.dependencies_clean?(ConfigFile.new(".").load_entries)
      if dependencies_clean || @force
        update_tracking_files_step
      else
        fail MultiRepoException, "Can't update because not all dependencies are clean"
      end
      
      Console.log_step("Done!")
    end
    
    def update_tracking_files_step
      if @main_only
        Console.log_step("Updating main repo...")
        update_main
      elsif @deps_only
        Console.log_step("Updating dependencies...")
        update_dependencies
      else
        Console.log_step("Updating main repo and dependencies...")
        update_dependencies
        update_main
      end
    end

    def update_dependencies
      Performer.dependencies.each do |dependency|
        path = dependency.config_entry.path
        name = dependency.config_entry.name
        update_tracking_files(path, name) if Utils.multirepo_enabled?(path)
      end
    end

    def update_main
      update_tracking_files(".", "main repo")
    end
    
    def update_tracking_files(path, name)
      Console.log_substep("Updating tracking files in #{name}")
      
      tracking_files = TrackingFiles.new(path)
      changed = tracking_files.update
      
      if changed
        Console.log_info("Updated tracking files")
      else
        Console.log_info("Tracking files are already up-to-date")
      end
      
      if @commit
        committed = tracking_files.commit("[multirepo] Updated tracking files manually")
        Console.log_info("Committed tracking files") if committed
      end
    end
  end
end

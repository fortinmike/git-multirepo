require "os"

require "multirepo/utility/console"
require "multirepo/utility/utils"

module MultiRepo
  class OpenCommand < Command
    self.command = "open"
    self.summary = "Opens repositories in the OS's file explorer."

    def self.options
      [
        ['[--all]', 'Open the main repository and all dependencies.'],
        ['[--main]', 'Open the main repository.'],
        ['[--deps]', 'Open dependencies.']
      ].concat(super)
    end
    
    def initialize(argv)
      @all = argv.flag?("all")
      @main_only = argv.flag?("main")
      @deps_only = argv.flag?("deps")
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
      
      if @main_only
        open_main
      elsif @deps_only
        open_dependencies
      else
        open_dependencies
        open_main
      end
    end

    def open_main
      Utils.reveal_in_default_file_browser(".")
    end

    def open_dependencies
      ConfigFile.new(".").load_entries.each do |entry|
        Utils.reveal_in_default_file_browser(entry.repo.path)
      end
    end
  end
end

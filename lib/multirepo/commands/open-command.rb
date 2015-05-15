require "os"

require "multirepo/utility/console"
require "multirepo/utility/utils"

module MultiRepo
  class OpenCommand < Command
    self.command = "open"
    self.summary = "Opens repositories in the OS's file explorer."

    def self.options
      [
        ['[--main]', 'Open the main repository.'],
        ['[--all]', 'Open the main repository and all dependencies.'],
      ].concat(super)
    end
    
    def initialize(argv)
      @main_only = argv.flag?("main")
      @all = argv.flag?("all")
      super
    end

    def validate!
      super
      unless validate_only_one_flag(@main_only, @all)
        help! "You can't provide more than one operation modifier (--deps, --main, etc.)"
      end
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      if @main_only
        open_main
      elsif @all
        open_dependencies
        open_main
      else
        open_dependencies
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
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
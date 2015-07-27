require "os"

require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/logic/repo-selection"

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
      @repo_selection = RepoSelection.new(argv)
      super
    end

    def validate!
      super
      help! "You can't provide more than one operation modifier (--deps, --main, etc.)" unless @repo_selection.valid?
    end
    
    def run
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      case @repo_selection.value
      when RepoSelection::MAIN
        open_main
      when RepoSelection::DEPS
        open_dependencies
      when RepoSelection::ALL
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

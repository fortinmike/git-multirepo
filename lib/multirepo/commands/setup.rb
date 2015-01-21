require "claide"

require_relative "../loader"

module MultiRepo
  class Setup < MultiRepo::Command
    self.command = "setup"
    self.summary = "Fetches and checks out dependencies as defined in the .multirepo file, and sets up git-multirepo's local pre-commit hook."
    
    def initialize(argv)
      super
    end
    
    def run
      entries = MultiRepo::Loader.load_entries(".multirepo")
      return unless entries
      
      puts entries.inspect
    end
  end
end
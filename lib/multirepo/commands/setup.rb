require "claide"

require_relative "../loader"

module MultiRepo
  class Setup < MultiRepo::Command
    self.command = "setup"
    self.summary = "Fetches and checks out the appropriate dependencies as defined in the .multirepo file."
    
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
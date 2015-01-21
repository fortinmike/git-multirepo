require "claide"

require_relative "../loader"
require_relative "../console"

module MultiRepo
  class Setup < MultiRepo::Command
    self.command = "setup"
    self.summary = "Fetches and checks out repositories as defined in the .multirepo file, and sets up git-multirepo's local pre-commit hook."
    
    def initialize(argv)
      super
    end
    
    def run
      MultiRepo::Console.log_step("Setupping multiple repositories...")
      
      @repos.each do |repo|
        next unless repo.setup
        repo.checkout
      end
      
      MultiRepo::Console.log_step("Done!")
    end
  end
end
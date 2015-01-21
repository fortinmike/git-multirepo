require "claide"

require_relative "../loader"
require_relative "../console"

module MultiRepo
  class Fetch < MultiRepo::Command
    self.command = "fetch"
    self.summary = "Performs a git fetch on all repositories."
    
    def initialize(argv)
      super
    end
    
    def run
      MultiRepo::Console.log_step("Fetching repositories...")
      
      @repos.each(&:fetch)
      MultiRepo::Git.run("fetch", true)
      
      MultiRepo::Console.log_step("Done!")
    end
  end
end
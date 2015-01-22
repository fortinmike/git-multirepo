require "claide"

require_relative "../loader"
require_relative "../console"

module MultiRepo
  class Fetch < Command
    self.command = "fetch"
    self.summary = "Performs a git fetch on all repositories."
    
    def initialize(argv)
      super
    end
    
    def run
      Console.log_step("Fetching repositories...")
      
      @repos.each do |repo|
        Console.log_substep("Fetching from #{repo.remote_url}...")
        repo.fetch
      end
      
      Console.log_step("Done!")
    end
  end
end
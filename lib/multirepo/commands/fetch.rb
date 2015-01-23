require "claide"

require "multirepo/utility/console"
require "multirepo/loader"

module MultiRepo
  class Fetch < Command
    self.command = "fetch"
    self.summary = "Performs a git fetch on all repositories."
    
    def initialize(argv)
      super
    end
    
    def run
      super
      
      Console.log_step("Fetching repositories...")
      
      @repos.each do |repo|
        Console.log_substep("Fetching from #{repo.remote_url}...")
        repo.fetch
      end
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
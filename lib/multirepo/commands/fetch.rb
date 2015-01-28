require "multirepo/utility/console"

module MultiRepo
  class Fetch < Command
    self.command = "fetch"
    self.summary = "Performs a git fetch on all dependencies."
    
    def run
      super
      ensure_multirepo_initialized
      
      Console.log_step("Fetching dependencies...")
      
      ConfigFile.load.each do |entry|
        Console.log_substep("Fetching from #{entry.repo.remote('origin').url}...")
        entry.repo.fetch
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
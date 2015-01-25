require "claide"

require "multirepo/utility/console"

module MultiRepo
  class Fetch < Command
    self.command = "fetch"
    self.summary = "Performs a git fetch on all dependency repositories."
    
    def run
      super
      
      Console.log_step("Fetching repositories...")
      
      self.load_entries
      @entries.each do |entry|
        Console.log_substep("Fetching from #{repo.remote_url}...")
        entry.fetch_repo
      end
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
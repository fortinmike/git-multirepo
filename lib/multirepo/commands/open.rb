require "multirepo/utility/console"

module MultiRepo
  class Open < Command
    self.command = "open"
    self.summary = "Opens this repo's dependencies in Finder or Windows Explorer."
    
    def run
      super
      ensure_multirepo_initialized
      
      self.load_entries
      @entries.each do |entry|
        `open #{entry.repo.working_copy}` # OS X
        # TODO: Windows
      end
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
require "claide"

require "multirepo/utility/console"

module MultiRepo
  class Open < Command
    self.command = "open"
    self.summary = "Opens this repo's dependencies in Finder or Windows Explorer."
    
    def initialize(argv)
      super
    end
    
    def run
      super
      
      @entries.each do |entry|
        `open #{entry.repo.working_copy}` # OS X
        # TODO: Windows
      end
    end
  end
end
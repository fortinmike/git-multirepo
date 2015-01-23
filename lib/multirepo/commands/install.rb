require "claide"

require_relative "../loader"
require_relative "../console"

module MultiRepo
  class Setup < Command
    self.command = "install"
    self.summary = "Clones and checks out repositories as defined in the .multirepo file, and installs git-multirepo's local pre-commit hook."
    
    def initialize(argv)
      super
    end
    
    def run
      return unless super
      
      Console.log_step("Setupping multiple repositories...")
      
      @entries.each do |entry|
        next unless entry.install
        entry.checkout
      end
      
      Console.log_step("Done!")
    end
  end
end
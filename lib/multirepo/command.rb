require "claide"

module MultiRepo
  class Command < CLAide::Command
    self.abstract_command = true
    self.command = "multi"
    self.version = VERSION
    self.description = DESCRIPTION
    
    def run
      @entries = Loader.load_entries(".multirepo")
      return @entries != nil
    end
  end
end
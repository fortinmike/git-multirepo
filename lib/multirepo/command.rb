require "claide"

module MultiRepo
  class Command < CLAide::Command
    self.abstract_command = true
    self.command = "multi"
    self.version = VERSION
    self.description = DESCRIPTION
    
    def run
      @repos = Loader.load_repos(".multirepo")
      return @repos != nil
    end
  end
end
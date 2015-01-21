require "colored"

module MultiRepo
  class Command < CLAide::Command
    self.abstract_command = true
    self.command = "multi"
    self.version = VERSION
    self.description = DESCRIPTION
    
    def initialize(argv)
      @repos = MultiRepo::Loader.load_repos(".multirepo")
      super
    end
  end
end
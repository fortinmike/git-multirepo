require "claide"
require "info"

module MultiRepo
  class Command < CLAide::Command
    self.abstract_command = true
    self.command = "multi"
    self.version = VERSION
    self.description = DESCRIPTION
    
    def run
      validate_in_work_tree
      
      @entries = Loader.load_entries
      if !@entries then raise "Failed to load entries from .multirepo file" end
    end
    
    def validate_in_work_tree
      inside = (Git.run("rev-parse --is-inside-work-tree", false).strip == "true")
      if !inside then raise "Not a git repository" end
    end
  end
end
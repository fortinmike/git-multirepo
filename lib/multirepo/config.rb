module MultiRepo
  class Config
    FILE = Pathname.new(".multirepo")
    
    def self.exists?
      FILE.exist?
    end
    
    def self.create
      template_path = MultiRepo.path_for_resource(".multirepo")
      FileUtils.cp(template_path, ".")
      Console.log_substep("Created .multirepo file")
    end
    
    def self.add(repo)
      entry = Entry.new(repo)
      
      if entry.exists?
        Console.log_info("There is already an entry for #{folder_name} in the .multirepo file")
      else
        entry.add
        Console.log_step("Added the repository #{repo.working_copy} to the .multirepo file")
      end
    end
  end
end
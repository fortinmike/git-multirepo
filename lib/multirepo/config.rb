module MultiRepo
  class Config
    FILE = Pathname.new(".multirepo")
    
    def self.exists?
      FILE.exist?
    end
    
    def self.create
      template_path = MultiRepo.path_for_resource(".multirepo")
      FileUtils.cp(template_path, ".")
    end
  end
end
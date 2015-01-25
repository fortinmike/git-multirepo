require_relative "config-entry"

module MultiRepo
  class ConfigFile
    FILE = Pathname.new(".multirepo")
    
    def self.exists?
      FILE.exist?
    end
    
    def self.create
      template_path = MultiRepo.path_for_resource(".multirepo")
      FileUtils.cp(template_path, ".")
    end
    
    def self.load_entries
      entries = Array.new
      
      ConfigFile::FILE.open("r").each_line do |line|
        next if line.start_with?("#") # Barebones comments support
        next if line.strip == "" # Skip empty lines
        components = line.split(" ")
        validate_components(line, components)
        entries.push(ConfigEntry.new(*components))
      end
      
      return entries
    end
    
    def self.validate_components(line, components)
      unless components.count == 3
        raise "Wrong entry format in .multirepo file: #{line}"
      end
    end
  end
end
require "pathname"

require "multirepo/utility/console"
require "multirepo/config"
require "multirepo/entry"

module MultiRepo
  class Loader
    def self.load_entries
      entries = Array.new
      
      Config::FILE.open("r").each_line do |line|
        next if line.start_with?("#") # Barebones comments support
        next if line.strip == "" # Skip empty lines
        components = line.split(" ")
        validate_components(line, components)
        entries.push(Entry.new(*components))
      end
      
      return entries
    end
    
    def self.check_exists(path)
      exists = path.exist?
      Console.log_error("'#{path.basename}' file does not exist.") unless exists
      return exists
    end
    
    def self.validate_components(line, components)
      unless components.count == 3
        raise "Wrong entry format in .multirepo file: #{line}"
      end
    end
  end
end
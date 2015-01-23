require "pathname"

require "multirepo/utility/console"
require "multirepo/entry"

module MultiRepo
  class Loader
    def self.load_entries(config_path)
      config = Pathname.new(config_path)
      return unless check_exists(config)
      
      entries = Array.new
      
      file = config.open("r")
      file.each_line do |line|
        next if line.start_with?("#") # Barebones comments support
        components = line.split(" ")
        entries.push(Entry.new(*components))
      end
      file.close
      
      return entries
    end
    
    def self.check_exists(path)
      exists = path.exist?
      Console.log_error("'#{path.basename}' file does not exist.") unless exists
      return exists
    end
  end
end
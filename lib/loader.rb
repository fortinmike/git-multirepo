require "entry"

module MultiRepo
  class Loader
    def self.load_entries(config_path)
      config = Pathname.new(config_path)
      return unless check_exists(config)
      
      entries = Array.new
      
      file = config.open("r")
      file.each_line do |line|
        components = line.split(" ")
        entries.push(MultiRepo::Entry.new(*components))
      end
      file.close
      
      return entries
    end
    
    def self.check_exists(path)
      exists = path.exist?
      puts "'#{path.basename}' file does not exist." unless exists
      return exists
    end
  end
end
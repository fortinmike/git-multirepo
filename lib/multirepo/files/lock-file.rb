require_relative "lock-entry"

module MultiRepo
  class LockFile
    FILE = Pathname.new(".multirepo.lock")
    
    def self.exists?
      FILE.exist?
    end
        
    def self.load_entries
      entries = Array.new
      
      FILE.open("r").each_line do |line|
        components = line.split(" ")
        validate_components(line, components)
        entries.push(LockEntry.new(*components))
      end
      
      return entries
    end
    
    def self.validate_components(line, components)
      unless components.count == 2
        raise "Wrong entry format in .multirepo.lock file: #{line}"
      end
    end
  end
end
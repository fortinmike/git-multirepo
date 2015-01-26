require_relative "lock-entry"
require_relative "config-file"

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
    
    def self.update
      repos = ConfigFile.load_entries.map{ |e| e.repo }
      
      FILE.open("w") do |f|
        repos.each do |r|
          entry_string = "#{r.working_copy_basename} #{r.head_hash}"
          f.puts(entry_string)
        end
      end
    end
    
    def self.validate_components(line, components)
      unless components.count == 2
        raise "Wrong entry format in .multirepo.lock file: #{line}"
      end
    end
  end
end
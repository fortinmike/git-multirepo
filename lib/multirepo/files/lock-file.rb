require "pathname"

require "multirepo/git/git"
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
        puts line
        components = line.split(" ")
        validate_components(line, components)
        entries.push(LockEntry.new(*components))
      end
      
      return entries
    end
    
    def self.update
      repos = ConfigFile.load_entries.map { |e| e.repo }
      lock_entries = repos.map { |r| LockEntry.new(r) }
      
      FILE.open("w") do |f|
        lock_entries.each do |lock_entry|
          f.puts(lock_entry.to_s)
        end
      end
      
      Git.run("add -A -f #{FILE.to_s}", false)
    end
    
    def self.validate_components(line, components)
      unless components.count == 2
        raise "Wrong entry format in .multirepo.lock file: #{line}"
      end
    end
  end
end
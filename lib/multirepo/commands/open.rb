require "multirepo/utility/console"
require "os"

module MultiRepo
  class Open < Command
    self.command = "open"
    self.summary = "Opens this repo's dependencies in Finder or Windows Explorer."
    
    def run
      super
      ensure_multirepo_initialized
      
      self.load_entries
      @entries.each do |entry|
        if OS.osx?
          `open "#{entry.repo.working_copy}"`
        elsif OS.windows?
          # TODO: Convert the path to a Windows-compatible format
          # http://stackoverflow.com/a/22644151
          `explorer "#{entry.repo.working_copy}"`
        end
      end
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
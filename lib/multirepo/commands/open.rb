require "os"

require "multirepo/utility/console"
require "multirepo/utility/utils"

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
          `open "#{entry.repo.path}"`
        elsif OS.windows?
          `explorer "#{Utils.convert_to_windows_path(entry.repo.path)}"`
        end
      end
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
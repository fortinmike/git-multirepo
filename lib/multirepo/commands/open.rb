require "os"

require "multirepo/utility/console"
require "multirepo/utility/utils"

module MultiRepo
  class Open < Command
    self.command = "open"
    self.summary = "Opens this repo's dependencies in the current OS's file explorer."
    
    def run
      super
      ensure_multirepo_initialized
      
      ConfigFile.load.each do |entry|
        if OS.osx?
          `open "#{entry.repo.path}"`
        elsif OS.windows?
          `explorer "#{Utils.convert_to_windows_path(entry.repo.path)}"`
        end
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
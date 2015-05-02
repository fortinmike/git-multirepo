require "os"

require "multirepo/utility/console"
require "multirepo/utility/utils"

module MultiRepo
  class OpenCommand < Command
    self.command = "open"
    self.summary = "Opens all dependencies in the current OS's file explorer."
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      ConfigFile.load_entries.each do |entry|
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
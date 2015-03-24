require "os"

module MultiRepo
  class EditCommand < Command
    self.command = "edit"
    self.summary = "Opens the .multirepo file in the default text editor."
    
    def run
      validate_in_work_tree
      ensure_multirepo_initialized
      
      if OS.posix?
        editor = `echo ${FCEDIT:-${VISUAL:-${EDITOR:-vi}}}`.strip
        system(editor, ".multirepo")
      elsif OS.windows?
        raise MultiRepoException, "The edit command is not implemented on Window yet."
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
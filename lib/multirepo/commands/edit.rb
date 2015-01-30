require "os"

module MultiRepo
  class Edit < Command
    self.command = "edit"
    self.summary = "Opens the .multirepo file in the default text editor."
    
    def run
      super
      ensure_multirepo_initialized
      
      if OS.posix?
        editor = `echo ${FCEDIT:-${VISUAL:-${EDITOR:-vi}}}`.strip
        system(editor, ".multirepo")
      elsif OS.windows?
        raise "The edit command is not implemented on Window yet."
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
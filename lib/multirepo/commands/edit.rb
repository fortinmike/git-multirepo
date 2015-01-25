module MultiRepo
  class Edit < Command
    self.command = "edit"
    self.summary = "Opens the .multirepo file in the default text editor."
    
    def run
      super
      editor = `echo ${FCEDIT:-${VISUAL:-${EDITOR:-vi}}}`.strip
      system(editor, ".multirepo")
      # TODO: Windows support
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
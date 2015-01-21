require "colored"

module MultiRepo
  class Console
    def self.log_step(message)
      print "-> ".white
      puts message.bold.green
    end
    
    def self.log_substep(message)
      print "-> ".white
      puts message.blue
    end
    
    def self.log_alternate_substep(message)
      print "-> ".white
      puts message.yellow
    end
    
    def self.log_warning(message)
      puts message.yellow
    end
    
    def self.log_error(message)
      puts message.red
    end
  end
end
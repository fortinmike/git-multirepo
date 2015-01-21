require "colored"

module MultiRepo
  class Console
    def self.log_step(message)
      print ">> ".white
      puts message.bold.green
    end
    
    def self.log_substep(message)
      puts message.blue
    end
    
    def self.log_warning(message)
      puts message.yellow
    end
    
    def self.log_error(message)
      puts message.red
    end
  end
end
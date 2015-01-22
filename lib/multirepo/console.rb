require "colored"

module MultiRepo
  class Console
    def self.log_step(message)
      print_arrow
      puts message.bold.green
    end
    
    def self.log_substep(message)
      print_arrow
      puts message.blue
    end
    
    def self.log_info(message)
      print_arrow
      puts message.white
    end
    
    def self.log_warning(message)
      print_arrow
      puts message.yellow
    end
    
    def self.log_error(message)
      print_arrow
      puts message.red
    end
    
    def self.print_arrow
      print "> ".white
    end
  end
end
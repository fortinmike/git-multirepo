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
    
    def self.ask_yes_no(message)
      answered = false
      while !answered
        print_arrow
        print message
        print " (y/n) "
        
        case $stdin.gets.strip.downcase
        when "y", "yes"
          answered = true
          return true
        when "n", "no"
          answered = true
          return false
        end
      end
    end
    
    def self.print_arrow
      print "> ".white
    end
  end
end
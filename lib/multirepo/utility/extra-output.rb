module MultiRepo
  class ExtraOutput
    def self.log(message)
      case Config.instance.extra_output
      when "teamcity"; log_teamcity(message)
      end
    end
    
    def self.log_teamcity(message)
      puts "##teamcity[progressMessage '#{message}']"
    end
  end
end

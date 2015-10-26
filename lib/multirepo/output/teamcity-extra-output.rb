module MultiRepo
  class TeamCityExtraOutput
    def progress(message)
      puts "##teamcity[progressMessage '#{message}']"
    end

    def error(message)
      puts "##teamcity[buildProblem description='#{message}']"
    end
  end
end

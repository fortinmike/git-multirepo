require_relative "teamcity-extra-output"

module MultiRepo
  class ExtraOutput < BasicObject
    def self.method_missing(sym, *args, &block)
      output = case Config.instance.extra_output
      when "teamcity"; TeamCityExtraOutput.new
      end
      puts "ExtraOutput #{Config.instance.extra_output}"
      output.send(sym, *args, &block)
    end
  end
end

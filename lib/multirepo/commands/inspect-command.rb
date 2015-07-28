require "multirepo/utility/console"
require "multirepo/utility/utils"

module MultiRepo
  class InspectCommandStats
    VERSION = "version"
    TRACKED = "tracked"
  end

  class InspectCommand < Command
    self.command = "inspect"
    self.summary = "Outputs various information about multirepo-enabled repos. For use in scripting and CI scenarios."
    
    def self.options
      [['<stat name>', 'The name of the statistic to output.']].concat(super)
    end
    
    def initialize(argv)
      stat = argv.shift_argument
      @stat = stat ? stat.downcase : nil
      super
    end

    def validate!
      super
      help! "You must provide a valid stat name. Available stats: \n    #{stats.join(', ')}" unless valid_stat?(@stat)
    end

    def stats
      InspectCommandStats.constants.map { |s| InspectCommandStats.const_get(s) }
    end

    def valid_stat?(stat)
      stats.include?(stat)
    end
    
    def run
      ensure_in_work_tree
      
      case @stat
      when InspectCommandStats::VERSION
        puts MetaFile.new(".").load.version
      when InspectCommandStats::TRACKED
        puts Utils.multirepo_tracked?(".").to_s
      end
    end
  end
end

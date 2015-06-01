require "multirepo/utility/console"
require "multirepo/utility/utils"

module MultiRepo
  class InspectCommand < Command
    self.command = "inspect"
    self.summary = "Outputs various information about multirepo-enabled repos. For use in scripting and CI scenarios."
    
    def self.options
      [
        ['[--version]', 'Outputs the multirepo version that was used to track this revision.'],
        ['[--tracked]', 'Whether the current revision is tracked by multirepo or not.']
      ].concat(super)
    end
    
    def initialize(argv)
      @version = argv.flag?("version")
      @tracked = argv.flag?("tracked")
      super
    end
    
    def validate!
      super
      unless validate_only_one_flag(@version, @tracked)
        help! "You can't provide more than one operation modifier (--version, --tracked, etc.)"
      end
    end
    
    def run
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      if @version
        puts MetaFile.new(".").load.version
      elsif @tracked
        puts Utils.is_multirepo_tracked(".").to_s
      end
    end
  end
end
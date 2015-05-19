require "multirepo/utility/console"
require "multirepo/logic/performer"

module MultiRepo
  class DoCommand < Command
    self.command = "do"
    self.summary = "Perform an arbitrary Git operation in the main repository, dependency repositories or all repositories."

    def self.options
      [
        ['[--main]', 'Perform the operation in the main repository only.'],
        ['[--deps]', 'Perform the operation in dependencies only.'],
        ['[--all]', 'Perform the operation in the main repository and all dependencies.']
      ].concat(super)
    end
    
    def initialize(argv)
      @operation = argv.shift_argument
      @main_only = argv.flag?("main")
      @deps_only = argv.flag?("deps")
      argv.flag?("all") # Eat the default flag!
      super
    end

    def validate!
      super
      unless validate_only_one_flag(@main_only, @deps_only, @all)
        help! "You can't provide more than one operation modifier (--deps, --main, etc.)"
      end
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      if @main_only
        
      elsif @deps_only
        
      else
        
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
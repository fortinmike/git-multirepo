require "multirepo/utility/console"
require "multirepo/logic/node"

module MultiRepo
  class MergeCommand < Command
    self.command = "merge"
    self.summary = "Performs a git merge on all dependencies, in the proper order."
    
    def self.options
      [['<ref>', 'The main repo tag, branch or commit id to merge.']].concat(super)
    end
    
    def initialize(argv)
      @ref = argv.shift_argument
      super
    end
    
    def validate!
      super
      help! "You must specify a ref to merge" unless @ref
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      Console.log_step("Merging #{@ref} ...")
      
      root_node = Node.new(".")
      
      puts root_node.ordered_descendants_including_self.inspect
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
require "multirepo/utility/console"
require "multirepo/logic/node"
require "multirepo/logic/revision-selector"
require "multirepo/logic/performer"

module MultiRepo
  class MergeCommand < Command
    self.command = "merge"
    self.summary = "Performs a git merge on all dependencies, in the proper order."
    
    def self.options
      [
        ['<ref>', 'The main repo tag, branch or commit id to merge.'],
        ['[--latest]', 'Merge the HEAD of each stored dependency branch instead of the commits recorded in the lock file.'],
        ['[--exact]', 'Merge the exact specified ref for each repo, regardless of what\'s stored in the lock file.']
      ].concat(super)
    end
    
    def initialize(argv)
      @ref = argv.shift_argument
      @checkout_latest = argv.flag?("latest")
      @checkout_exact = argv.flag?("exact")
      super
    end
    
    def validate!
      super
      help! "You must specify a ref to merge" unless @ref
      help! "You can't provide more than one operation modifier (--latest, --exact, etc.)" if @checkout_latest && @checkout_exact
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
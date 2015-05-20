require "multirepo/utility/console"
require "multirepo/git/git-runner"
require "multirepo/logic/performer"

module MultiRepo
  class DoCommand < Command
    self.command = "do"
    self.summary = "Perform an arbitrary Git operation in the main repository, dependency repositories or all repositories."

    def self.options
      [
        ['"<operation>"', 'The git command to perform, between quotes, omitting the executable name (ex: "reset --hard HEAD")'],
        ['[--main]', 'Perform the operation in the main repository only.'],
        ['[--deps]', 'Perform the operation in dependencies only.'],
        ['[--all]', 'Perform the operation in the main repository and all dependencies.']
      ].concat(super)
    end
    
    def initialize(argv)
      @operation = argv.shift_argument
      @all = argv.flag?("all")
      @main_only = argv.flag?("main")
      @deps_only = argv.flag?("deps")
      super
    end

    def validate!
      super
      unless validate_only_one_flag(@all, @main_only, @deps_only)
        help! "You can't provide more than one operation modifier (--deps, --main, etc.)"
      end
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      if @main_only
        message = "Perform operation on the #{'main repo'.bold}:\n  git #{@operation}"
        op = lambda { perform_operation_on_main(@operation) }
      elsif @deps_only
        message = "Perform operation on #{'dependencies'.bold}:\n  git #{@operation}"
        op = lambda { perform_operation_on_dependencies(@operation) }
      else
        message = "Perform operation on #{'dependencies'.bold} and the #{'main repo'.bold}:\n  git #{@operation}"
        op = lambda {
          perform_operation_on_dependencies(@operation) # Ordered dependencies first
          perform_operation_on_main(@operation) # Main last
        }
      end
      
      raise MultiRepoException, "Operation cancelled" unless Console.ask_yes_no(message)
      
      op.call
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end

    def perform_operation_on_main(operation)
      perform_operation(".", operation)
    end

    def perform_operation_on_dependencies(operation)
      Performer.perform_on_dependencies do |config_entry, lock_entry|
        perform_operation(config_entry.repo.path, operation)
      end
    end

    def perform_operation(path, operation)
      Console.log_step("Performing operation on '#{path}'")
      Console.log_info("git #{operation}")
      GitRunner.run_in_working_dir(path, operation, Runner::Verbosity::OUTPUT_ALWAYS)
    end
  end
end
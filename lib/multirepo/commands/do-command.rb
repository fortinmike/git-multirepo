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
      help! "You must provide a git operation to perform" unless @operation
      unless validate_only_one_flag(@all, @main_only, @deps_only)
        help! "You can't provide more than one operation modifier (--deps, --main, etc.)"
      end
    end
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      @operation = @operation.sub(/^git /, "")
      
      success = true
      if @main_only
        success &= perform_operation_on_main(@operation)
      elsif @deps_only
        success &= perform_operation_on_dependencies(@operation)
      else
        success &= perform_operation_on_dependencies(@operation) # Ordered dependencies first
        success &= perform_operation_on_main(@operation) # Main last
      end
      
      Console.log_warning("Some operations finished with non-zero exit status. Please review the above.") unless success
    end
    
    def perform_operation_on_main(operation)
      perform_operation(".", operation)
    end

    def perform_operation_on_dependencies(operation)
      success = true
      Performer.dependencies.each do |dependency|
        success &= perform_operation(dependency.config_entry.repo.path, operation)
      end
      return success
    end

    def perform_operation(path, operation)
      Console.log_step("Performing operation on '#{path}'")
      GitRunner.run_in_working_dir(path, operation, Runner::Verbosity::OUTPUT_ALWAYS)
      GitRunner.last_command_succeeded
    end
  end
end
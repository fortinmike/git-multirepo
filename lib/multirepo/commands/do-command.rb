require_relative "command"
require "multirepo/utility/utils"
require "multirepo/utility/console"
require "multirepo/files/config-file"
require "multirepo/git/repo"
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
      ensure_in_work_tree
      ensure_multirepo_enabled

      @operation = @operation.sub(/^git /, "")
      
      success = true
      if @main_only
        confirm_main_repo_operation
        success &= perform_operation_on_main(@operation)
      elsif @deps_only
        confirm_dependencies_operation
        success &= perform_operation_on_dependencies(@operation)
      else
        confirm_main_repo_operation
        confirm_dependencies_operation
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
      GitRunner.run_as_system(path, operation)
      GitRunner.last_command_succeeded
    end
    
    def confirm_main_repo_operation
      unless main_repo_clean?
        Console.log_warning("Main repo contains uncommitted changes")
        fail MultiRepoException, "Aborted" unless Console.ask("Proceed anyway?")
      end
    end
    
    def confirm_dependencies_operation
      unless dependencies_clean?
        Console.log_warning("Some dependencies contain uncommitted changes")
        fail MultiRepoException, "Aborted" unless Console.ask("Proceed anyway?")
      end
    end
    
    def main_repo_clean?
      Repo.new(".").clean?
    end
    
    def dependencies_clean?
      config_entries = ConfigFile.new(".").load_entries
      return Utils.dependencies_clean?(config_entries)
    end
  end
end

require_relative "ref"
require_relative "git-runner"

module MultiRepo
  class Branch < Ref
    def exists?
      lines = GitRunner.run_in_working_dir(@repo.path, "branch", Runner::Verbosity::OUTPUT_NEVER).split("\n")
      branch_names = lines.map { |line| line.tr("* ", "")}
      branch_names.include?(@name)
    end
    
    def create
      GitRunner.run_in_working_dir(@repo.path, "branch #{@name}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def push
      GitRunner.run_in_working_dir(@repo.path, "push -u origin #{@name}", Runner::Verbosity::OUTPUT_ON_ERROR)
    end
    
    def checkout
      GitRunner.run_in_working_dir(@repo.path, "checkout #{@name}", Runner::Verbosity::OUTPUT_ON_ERROR)
      GitRunner.last_command_succeeded
    end
  end
end
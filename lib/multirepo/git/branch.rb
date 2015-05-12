require_relative "git-runner"

module MultiRepo
  class Branch
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end

    def exists?
      lines = GitRunner.run_in_working_dir(@repo.path, "branch", Runner::Verbosity::OUTPUT_NEVER).split("\n")
      branch_names = lines.map { |line| line.tr("* ", "")}
      branch_names.include?(@name)
    end

    def create(remote_tracking = false)
      GitRunner.run_in_working_dir(@repo.path, "branch #{@name}", Runner::Verbosity::OUTPUT_ON_ERROR)
      GitRunner.run_in_working_dir(@repo.path, "push -u origin #{name}", Runner::Verbosity::OUTPUT_ON_ERROR) if remote_tracking
    end
    
    def checkout
      GitRunner.run_in_working_dir(@repo.path, "checkout #{@name}", Runner::Verbosity::OUTPUT_ON_ERROR)
      GitRunner.last_command_succeeded
    end
  end
end
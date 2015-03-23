require_relative "git"

module MultiRepo
  class Branch
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end

    def exists?
      lines = Git.run_in_working_dir(@repo.path, "branch", Runner::Verbosity::NEVER_OUTPUT).split("\n")
      branch_names = lines.map { |line| line.tr("* ", "")}
      branch_names.include?(@name)
    end

    def create(remote_tracking = false)
      Git.run_in_working_dir(@repo.path, "branch #{@name}", Runner::Verbosity::OUTPUT_ON_ERROR)
      Git.run_in_working_dir(@repo.path, "push -u origin #{name}", Runner::Verbosity::OUTPUT_ON_ERROR) if remote_tracking
    end
    
    def checkout
      Git.run_in_working_dir(@repo.path, "checkout #{@name}", Runner::Verbosity::OUTPUT_ON_ERROR)
      Git.last_command_succeeded
    end
  end
end
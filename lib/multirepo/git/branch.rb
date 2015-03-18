require_relative "git"

module MultiRepo
  class Branch
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end

    def exists?
      lines = Git.run_in_working_dir(@repo.path, "branch", false).split("\n")
      branch_names = lines.map { |line| line.tr("* ", "")}
      branch_names.include?(@name)
    end

    def create(remote_tracking = false)
      Git.run_in_working_dir(@repo.path, "branch #{@name}", false)
      Git.run_in_working_dir(@repo.path, "push -u origin #{name}", false) if remote_tracking
    end
    
    def checkout
      Git.run_in_working_dir(@repo.path, "checkout #{@name}", false)
      Git.last_command_succeeded
    end
  end
end
require_relative "ref"
require_relative "git-runner"

module MultiRepo
  class Branch < Ref
    def exists?
      lines = GitRunner.run(@repo.path, "branch", Verbosity::OUTPUT_NEVER).split("\n")
      branch_names = lines.map { |line| line.tr("* ", "")}
      branch_names.include?(@name)
    end
    
    def upstream_branch
      output = GitRunner.run(@repo.path, "config --get branch.#{@name}.merge", Verbosity::OUTPUT_NEVER)
      output.sub!("refs/heads/", "")
      return nil if output == ""
      Branch.new(@repo, "origin/#{output}")
    end
    
    def create
      GitRunner.run(@repo.path, "branch #{@name}", Verbosity::OUTPUT_ON_ERROR)
    end
    
    def push
      GitRunner.run(@repo.path, "push -u origin #{@name}", Verbosity::OUTPUT_ON_ERROR)
    end
    
    def checkout
      GitRunner.run(@repo.path, "checkout #{@name}", Verbosity::OUTPUT_ON_ERROR)
      GitRunner.last_command_succeeded
    end
  end
end
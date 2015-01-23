require_relative "git"

module MultiRepo
  class Branch
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def exists?
      lines = Git.run(@repo.working_copy, "branch", false).split("\n")
      branch_names = lines.map { |line| line.tr("* ", "")}
      branch_names.include?(@name)
    end
    
    def create(remote_tracking)
      Git.run(@repo.working_copy, "branch #{@name}", false)
      if remote_tracking then Git.run(@repo.working_copy, "push -u origin #{name}", false) end
      $?.exitstatus == 0
    end
    
    def checkout
      Git.run(@repo.working_copy, "checkout #{@name}", false)
      $?.exitstatus == 0
    end
  end
end
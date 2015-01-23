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
    
    def create
      Git.run(@repo.working_copy, "branch #{@name}", false)
      $?.exitstatus == 0
    end
    
    def checkout
      Git.run(@repo.working_copy, "checkout #{@name}", false)
      $?.exitstatus == 0
    end
  end
end
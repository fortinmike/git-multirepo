require_relative "git"

module MultiRepo
  class Branch
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def checkout
      Git.run_in_working_dir(@repo.path, "checkout #{@name}", false)
      $?.exitstatus == 0
    end
  end
end
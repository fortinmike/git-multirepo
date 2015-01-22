module MultiRepo
  class Branch
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def exists?
      return true
    end
    
    def create
      MultiRepo::Git.run(@repo.working_copy, "branch #{@name}", false)
      return $?.exitstatus == 0
    end
    
    def checkout
      MultiRepo::Git.run(@repo.working_copy, "checkout #{@name}", false) 
      return $?.exitstatus == 0
    end
  end
end
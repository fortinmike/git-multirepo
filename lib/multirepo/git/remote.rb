require_relative "git"

module MultiRepo
  class Remote
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def url
      Git.run(@repo.working_copy, "config --get remote.#{@name}.url", false).strip
    end
  end
end
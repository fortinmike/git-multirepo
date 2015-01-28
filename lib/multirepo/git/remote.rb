require_relative "git"

module MultiRepo
  class Remote
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def url
      Git.run(@repo.path, "config --get remote.#{@name}.url", false).strip
    end
  end
end
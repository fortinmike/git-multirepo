require_relative "git-runner"

module MultiRepo
  class Remote
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def url
      output = GitRunner.run(@repo.path, "config --get remote.#{@name}.url", Verbosity::OUTPUT_NEVER).strip
      return output == "" ? nil : output
    end
  end
end
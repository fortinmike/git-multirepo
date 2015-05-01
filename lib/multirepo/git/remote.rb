require_relative "git"

module MultiRepo
  class Remote
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def url
      output = Git.run_in_working_dir(@repo.path, "config --get remote.#{@name}.url", Runner::Verbosity::NEVER_OUTPUT).strip
      return output == "" ? nil : output
    end
  end
end
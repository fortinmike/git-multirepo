require "singleton"

module MultiRepo
  class Config
    include Singleton
    
    attr_accessor :verbose
    @verbose = false
    
    attr_accessor :running_git_hook
    @running_git_hook = false
  end
end
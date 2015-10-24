require "singleton"

module MultiRepo
  class Config
    include Singleton
    
    attr_accessor :verbose
    @verbose = false
    
    attr_accessor :running_git_hook
    @running_git_hook = false

    attr_accessor :git_executable
    @git_executable = nil
    
    attr_accessor :extra_output
    @extra_output = nil
  end
end

require "singleton"

module MultiRepo
  class Config
    include Singleton
    
    attr_accessor :verbose
    @verbose = false
  end
end
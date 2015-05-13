module MultiRepo
  class MergeDescriptor
    attr_accessor :name
    attr_accessor :path
    attr_accessor :revision
    
    def initialize(name, path, revision)
      @name = name
      @path = path
      @revision = revision
    end
  end
end
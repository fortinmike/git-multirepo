module MultiRepo
  class Change
    attr_accessor :kind
    attr_accessor :path
    
    def initialize(line)
      @kind = line[0...2].strip
      @path = line[3..-1]
    end
  end
end
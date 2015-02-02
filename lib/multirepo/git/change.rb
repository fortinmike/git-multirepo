module MultiRepo
  class Change
    attr_accessor :status
    attr_accessor :path
    
    def initialize(line)
      @status = line[0...2].strip
      @path = line[3..-1]
    end
  end
end
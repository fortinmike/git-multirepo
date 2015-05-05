require "multirepo/files/config-file"

module MultiRepo
  class Node
    attr_accessor :path
    
    def initialize(path)
      @path = path
    end
    
    def children
      return [] unless Utils.is_multirepo_enabled(@path)
      config_entries = ConfigFile.new(@path).load_entries
      return config_entries.map { |e| Node.new(e.path) }
    end
    
    def ==(object)
      object.class == self.class &&
      object.path == path
    end
  end
end
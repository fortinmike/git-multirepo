require "multirepo/files/config-file"

module MultiRepo
  class Node
    attr_accessor :path
    attr_accessor :depth
    
    def initialize(path, depth = 0)
      @path = path
      @depth = depth
    end
    
    def name
      Pathname.new(File.expand_path(@path)).basename.to_s
    end
    
    def children
      return [] unless Utils.is_multirepo_enabled(@path)
      config_entries = ConfigFile.new(@path).load_entries
      return config_entries.map { |e| Node.new(e.path, @depth + 1) }
    end
    
    def ordered_descendants_including_self
      return ordered_descendants.push(self)
    end
    
    def ordered_descendants
      descendants = find_descendants_recursive(self)
      
      unique_paths = descendants.map{ |d| d.path }.uniq
      unique_nodes = unique_paths.collect do |path|
        nodes_for_path = descendants.select { |d| d.path == path }
        next nodes_for_path.sort{ |n| n.depth }.first
      end
      
      return unique_nodes.sort_by{ |d| d.depth }.reverse
    end
    
    def find_descendants_recursive(node)
      descendants = node.children
      descendants.each { |d| descendants.push(*find_descendants_recursive(d)) }
      return descendants
    end
  end
end
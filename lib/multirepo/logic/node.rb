require "multirepo/files/config-file"
require "multirepo/utility/utils"

module MultiRepo
  class Node
    attr_accessor :path
    attr_accessor :depth
    attr_accessor :parent
    
    def initialize(path, parent = nil, depth = 0)
      @path = path
      @depth = depth
      @parent = parent
    end
    
    def name
      Pathname.new(File.expand_path(@path)).basename.to_s
    end
    
    def children
      return [] unless Utils.multirepo_enabled?(@path)
      config_entries = ConfigFile.new(@path).load_entries
      return config_entries.map { |e| Node.new(e.path, self, @depth + 1) }
    end
    
    def ordered_descendants_including_self
      return ordered_descendants.push(self)
    end
    
    def ordered_descendants
      descendants = find_descendants_recursive(self)
      
      unique_paths = descendants.map(&:path).uniq
      unique_nodes = unique_paths.collect do |path|
        nodes_for_path = descendants.select { |d| d.path == path }
        next nodes_for_path.sort_by(&:depth).first
      end
      
      return unique_nodes.sort_by(&:depth).reverse
    end
    
    def find_descendants_recursive(node)
      ensure_no_dependency_cycle(node)
      
      descendants = node.children
      descendants.each { |d| descendants.push(*find_descendants_recursive(d)) }
      return descendants
    end
    
    def ensure_no_dependency_cycle(node)
      parent = node.parent
      visited = []
      while parent
        visited.push(parent)
        if parent == node
          Console.log_warning("Dependency cycle detected:")
          visited.reverse.each_with_index do |n, i|
            description = "[first]" if i == visited.count - 1
            description = "itself" if visited.count == 1
            Console.log_warning("'#{n.path}' depends on #{description}")
          end
          fail MultiRepoException, "Dependency cycles are not supported by multirepo."
        end
        parent = parent.parent # Will eventually be nil (root node), which will break out of the loop
      end
    end
    
    def ==(other)
      other.class == self.class &&
      otherPath = Utils.standard_path(other.path)
      thisPath = Utils.standard_path(@path)
      otherPath.casecmp(thisPath) == 0
    end
  end
end

require "os"
require "graphviz"

require "multirepo/utility/console"
require "multirepo/logic/node"

module MultiRepo
  class GraphCommand < Command
    self.command = "graph"
    self.summary = "Graphs the dependency tree from the current repository."
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      root = Node.new(".")
      graph = GraphViz.new(:G, :type => :digraph)
      build_graph_recursive(graph, root)
      
      path = File.expand_path("~/Desktop/#{root.name}-graph.png")
      
      begin
        graph.output(:png => path)
      rescue StandardError => e
        Console.log_error(e.message)
      end
      
      Console.log_step("Generated graph image #{path}")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def build_graph_recursive(graph, node)
      parent_graph_node = graph.add_nodes(node.name)
      node.children.each do |child_node|
        child_graph_node = graph.add_nodes(child_node.name)
        graph.add_edges(parent_graph_node, child_graph_node)
        build_graph_recursive(graph, child_node)
      end
    end
  end
end
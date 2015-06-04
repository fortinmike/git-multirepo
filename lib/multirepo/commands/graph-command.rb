require "os"
require "graphviz"

require "multirepo/utility/utils"
require "multirepo/utility/console"
require "multirepo/logic/node"

module MultiRepo
  class GraphCommand < Command
    self.command = "graph"
    self.summary = "Graphs the dependency tree from the current repository."
    
    def run
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      root = Node.new(".")
      graph = GraphViz.new(:G, :type => :digraph)
      build_graph_recursive(graph, root)
      
      path = File.expand_path("~/Desktop/#{root.name}-graph.png")
      
      begin
        graph.output(:png => path)
        Utils.open_in_default_app(path)
      rescue StandardError => e
        Console.log_error(e.message)
        raise MultiRepoException, "Could not generate graph image because an error occurred during graph generation"
      end
      
      Console.log_step("Generated graph image #{path}")
    end
    
    def build_graph_recursive(graph, node)
      parent_graph_node = graph.add_nodes(node.name)
      node.children.each do |child_node|
        child_graph_node = graph.add_node(child_node.name)
        graph.add_edge(parent_graph_node, child_graph_node)
        build_graph_recursive(graph, child_node)
      end
    end
  end
end

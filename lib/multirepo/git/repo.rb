require_relative "branch"
require_relative "remote"

module MultiRepo
  class Repo
    attr_accessor :path
    attr_accessor :basename
    
    def initialize(path)
      @path = path
      @basename = Pathname.new(path).basename.to_s
    end
    
    # Inspection
    
    def exists?
      Git.is_inside_git_repo(@path)
    end
    
    def current_branch
      branch = Git.run_in_working_dir(@path, "rev-parse --abbrev-ref HEAD", false).strip
      branch != "HEAD" ? branch : nil
    end
    
    def head_hash
      Git.run_in_working_dir(@path, "rev-parse HEAD", false).strip
    end
    
    def changes
      output = Git.run_in_working_dir(@path, "status --porcelain", false)
      puts output
      output.split("\n").each{ |f| f.strip }.delete_if{ |f| f == "" }
    end
    
    def is_clean?
      return changes.count == 0
    end
    
    # Operations
    
    def fetch
      Git.run_in_working_dir(@path, "fetch", true)
      $?.exitstatus == 0
    end
    
    def clone(url)
      Git.run_in_working_dir("clone #{url} #{@path}", true)
      $?.exitstatus == 0
    end
    
    def checkout(ref)
      Git.run_in_working_dir(@path, "checkout #{ref}", false)
      $?.exitstatus == 0
    end
    
    # Remotes and branches
    
    def branch(name)
      Branch.new(self, name)
    end
    
    def remote(name)
      Remote.new(self, name)
    end
  end
end
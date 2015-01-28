require_relative "branch"
require_relative "remote"

module MultiRepo
  class Repo
    attr_accessor :working_copy
    attr_accessor :working_copy_basename
    
    def initialize(working_copy)
      @working_copy = working_copy
      @working_copy_basename = Pathname.new(working_copy).basename.to_s
    end
    
    # Inspection
    
    def exists?
      Git.is_inside_git_repo(@working_copy)
    end
    
    def current_branch
      branch = Git.run(@working_copy, "rev-parse --abbrev-ref HEAD", false).strip
      branch != "HEAD" ? branch : nil
    end
    
    def head_hash
      Git.run(@working_copy, "rev-parse HEAD", false).strip
    end
    
    def changes
      output = Git.run(@working_copy, "status --porcelain", false)
      puts output
      output.split("\n").each{ |f| f.strip }.delete_if{ |f| f == "" }
    end
    
    # Operations
    
    def fetch
      Git.run(@working_copy, "fetch", true)
      $?.exitstatus == 0
    end
    
    def clone(remote_url)
      Git.run("clone #{remote_url} #{@working_copy}", true)
      $?.exitstatus == 0
    end
    
    def checkout(ref)
      Git.run(@working_copy, "checkout #{ref}", false)
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
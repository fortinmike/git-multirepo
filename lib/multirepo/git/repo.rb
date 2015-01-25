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
    
    def exists?
      Git.is_inside_git_repo(@working_copy)
    end
    
    def current_branch
      Git.run(@working_copy, "rev-parse --abbrev-ref HEAD", false)
    end
    
    def head_hash
      Git.run(@working_copy, "rev-parse HEAD", false)
    end
    
    def fetch
      Git.run(@working_copy, "fetch", true)
      $?.exitstatus == 0
    end
    
    def clone(remote_url)
      Git.run("clone #{remote_url} #{@working_copy}", true)
      $?.exitstatus == 0
    end
    
    def branch(name)
      Branch.new(self, name)
    end
    
    def remote(name)
      Remote.new(self, name)
    end
  end
end
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
      Git.run(@working_copy, "rev-parse --abbrev-ref HEAD", false)
    end
    
    def head_hash
      Git.run(@working_copy, "rev-parse HEAD", false)
    end
    
    def has_uncommitted_changes
      return untracked_files.any? || modified_files.any? || staged_files.any?
    end
    
    def untracked_files
      output = Git.run(@working_copy, "ls-files --exclude-standard --others", false)
      output.split("\n").each{ |f| f.strip }.delete_if{ |f| f == "" }
    end
    
    def modified_files
      output = Git.run(@working_copy, "ls-files --modified", false)
      result = output.split("\n").each{ |f| f.strip }.delete_if{ |f| f == "" }
      puts result
      result
    end
    
    def staged_files
      output = Git.run(@working_copy, "diff --name-only --cached", false)
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
    
    # Remotes and branches
    
    def branch(name)
      Branch.new(self, name)
    end
    
    def remote(name)
      Remote.new(self, name)
    end
  end
end
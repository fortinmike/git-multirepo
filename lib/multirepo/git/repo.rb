require_relative "branch"
require_relative "remote"
require_relative "change"

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
      lines = output.split("\n").each{ |f| f.strip }.delete_if{ |f| f == "" }
      changes = lines.map { |l| Change.new(l) }
      
      # Workaround for what seems like a git bug (or some incomprehension on my part)
      # When providing a pathspec pointing to an untracked file when committing the main
      # repo and the pre-commit hook looks like so: 'git -C "../some-dependency" status --porcelain'
      # then the output of "git status" shows all unmodified files as both
      # D[eleted] and ??[untracked] simultaneously. They should simply not be listed as modified in any way.
      deleted = changes.select { |c| c.status == "D" }
      untracked = changes.select { |c| c.status == "??" }
      changes.delete_if { |c| deleted.any? { |d| d.path == c.path } && untracked.any? { |u| u.path == c.path } }
      
      return changes
    end
    
    def is_clean?
      return changes.count == 0
    end
    
    # Operations
    
    def fetch
      Git.run_in_working_dir(@path, "fetch --progress", true)
      Runner.last_command_succeeded
    end
    
    def clone(url)
      Git.run_in_current_dir("clone #{url} #{@path} --progress", true)
      Runner.last_command_succeeded
    end
    
    def checkout(ref)
      Git.run_in_working_dir(@path, "checkout #{ref}", false)
      Runner.last_command_succeeded
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
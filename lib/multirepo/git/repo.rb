require_relative "branch"
require_relative "remote"
require_relative "commit"
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
      return false unless Dir.exist?("#{@path}/.git")
      return Git.run_in_working_dir(@path, "rev-parse --is-inside-work-tree", Runner::Verbosity::NEVER_OUTPUT).strip == "true"
    end
    
    def head_born?
      result = Git.run_in_working_dir(@path, "rev-parse HEAD --", Runner::Verbosity::NEVER_OUTPUT).strip
      return !result.start_with?("fatal: bad revision")
    end
    
    def current_branch
      branch = Git.run_in_working_dir(@path, "rev-parse --abbrev-ref HEAD", Runner::Verbosity::NEVER_OUTPUT).strip
      branch != "HEAD" ? branch : nil
    end
    
    def head_hash
      Git.run_in_working_dir(@path, "rev-parse HEAD", Runner::Verbosity::NEVER_OUTPUT).strip
    end
    
    def changes
      output = Git.run_in_working_dir(@path, "status --porcelain", Runner::Verbosity::NEVER_OUTPUT)
      lines = output.split("\n").each{ |f| f.strip }.delete_if{ |f| f == "" }
      lines.map { |l| Change.new(l) }
    end
    
    def is_clean?
      return changes.count == 0
    end
    
    # Operations
    
    def fetch
      Git.run_in_working_dir(@path, "fetch --progress", Runner::Verbosity::ALWAYS_OUTPUT)
      Runner.last_command_succeeded
    end
    
    def clone(url)
      Git.run_in_current_dir("clone #{url} #{@path} --progress", Runner::Verbosity::ALWAYS_OUTPUT)
      Runner.last_command_succeeded
    end
    
    def checkout(ref)
      Git.run_in_working_dir(@path, "checkout #{ref}", Runner::Verbosity::OUTPUT_ON_ERROR)
      Runner.last_command_succeeded
    end
    
    # Remotes and branches
    
    def branch(name)
      Branch.new(self, name)
    end
    
    def remote(name)
      Remote.new(self, name)
    end
    
    def commit(ref)
      Commit.new(self, ref)
    end
  end
end
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
      return GitRunner.run_in_working_dir(@path, "rev-parse --is-inside-work-tree", Runner::Verbosity::OUTPUT_NEVER).strip == "true"
    end
    
    def head_born?
      result = GitRunner.run_in_working_dir(@path, "rev-parse HEAD --", Runner::Verbosity::OUTPUT_NEVER).strip
      return !result.start_with?("fatal: bad revision")
    end
    
    def current_branch_name
      branch = GitRunner.run_in_working_dir(@path, "rev-parse --abbrev-ref HEAD", Runner::Verbosity::OUTPUT_NEVER).strip
      branch != "HEAD" ? branch : nil
    end
    
    def head_hash
      GitRunner.run_in_working_dir(@path, "rev-parse HEAD", Runner::Verbosity::OUTPUT_NEVER).strip
    end
    
    def changes
      output = GitRunner.run_in_working_dir(@path, "status --porcelain", Runner::Verbosity::OUTPUT_NEVER)
      lines = output.split("\n").each{ |f| f.strip }.delete_if{ |f| f == "" }
      lines.map { |l| Change.new(l) }
    end
    
    def is_clean?
      return changes.count == 0
    end
    
    # Operations
    
    def fetch
      GitRunner.run_in_working_dir(@path, "fetch --prune --progress", Runner::Verbosity::OUTPUT_ALWAYS)
      Runner.last_command_succeeded
    end
    
    def clone(url)
      GitRunner.run_in_current_dir("clone #{url} #{@path} --progress", Runner::Verbosity::OUTPUT_ALWAYS)
      Runner.last_command_succeeded
    end
    
    def checkout(ref)
      GitRunner.run_in_working_dir(@path, "checkout #{ref}", Runner::Verbosity::OUTPUT_ON_ERROR)
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
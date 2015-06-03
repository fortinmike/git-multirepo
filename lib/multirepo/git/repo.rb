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
      return GitRunner.run(@path, "rev-parse --is-inside-work-tree", Verbosity::OUTPUT_NEVER).strip == "true"
    end
    
    def head_born?
      result = GitRunner.run(@path, "rev-parse HEAD --", Verbosity::OUTPUT_NEVER).strip
      return !result.start_with?("fatal: bad revision")
    end
    
    def current_revision
      (current_branch || current_commit).name
    end
    
    def clean?
      changes.count == 0
    end
    
    def local_branches
      branches_by_removing_prefix(/^refs\/heads\//)
    end
    
    def remote_branches
      branches_by_removing_prefix(/^refs\/remotes\//)
    end
    
    def changes
      output = GitRunner.run(@path, "status --porcelain", Verbosity::OUTPUT_NEVER)
      lines = output.split("\n").each{ |f| f.strip }.delete_if{ |f| f == "" }
      lines.map { |l| Change.new(l) }
    end
    
    # Operations
    
    def fetch
      GitRunner.run_as_system(@path, "fetch --prune --progress")
      GitRunner.last_command_succeeded
    end
    
    def clone(url, branch = nil)
      if branch != nil
        GitRunner.run_as_system(".", "clone #{url} -b #{branch} #{@path} --progress")
      else
        GitRunner.run_as_system(".", "clone #{url} #{@path} --progress")
      end
      GitRunner.last_command_succeeded
    end
    
    def checkout(ref_name)
      GitRunner.run(@path, "checkout #{ref_name}", Verbosity::OUTPUT_ON_ERROR)
      GitRunner.last_command_succeeded
    end
    
    # Current
    
    def head
      return nil unless exists? && head_born?
      Ref.new(self, "HEAD")
    end
    
    def current_commit
      return nil unless exists? && head_born?
      Commit.new(self, head.commit_id)
    end
    
    def current_branch
      return nil unless exists? && head_born?
      name = GitRunner.run(@path, "rev-parse --abbrev-ref HEAD", Verbosity::OUTPUT_NEVER).strip
      Branch.new(self, name)
    end
    
    # Factory methods
    
    def ref(name)
      Ref.new(self, name)
    end
    
    def branch(name)
      Branch.new(self, name)
    end
    
    def remote(name)
      Remote.new(self, name)
    end
    
    def commit(id)
      Commit.new(self, id)
    end
    
    # Private helper methods
    
    private
    
    def branches_by_removing_prefix(prefix_regex)
      output = GitRunner.run(@path, "for-each-ref --format='%(refname)'", Verbosity::OUTPUT_NEVER)
      all_refs = output.strip.split("\n")

      # Remove surrounding quotes on Windows
      all_refs = all_refs.map { |l| l.sub(/^\'/, "").sub(/\'$/, "") }

      full_names = all_refs.select { |r| r =~ prefix_regex }
      names = full_names.map{ |f| f.sub(prefix_regex, "") }.delete_if{ |n| n =~ /HEAD$/}
      names.map { |b| Branch.new(self, b) }
    end
  end
end
require_relative "git-runner"

module MultiRepo
  class Ref
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def exists?
      output = GitRunner.run(@repo.path, "rev-parse --verify --quiet #{@name}", Verbosity::OUTPUT_NEVER).strip
      return output != ""
    end
    
    def commit_id
      GitRunner.run(@repo.path, "rev-parse #{@name}", Verbosity::OUTPUT_NEVER).strip
    end
    
    def short_commit_id
      GitRunner.run(@repo.path, "rev-parse --short #{@name}", Verbosity::OUTPUT_NEVER).strip
    end
    
    def merge_commit?
      lines = GitRunner.run(@repo.path, "cat-file -p #{@name}", Verbosity::OUTPUT_NEVER).split("\n")
      parents = lines.grep(/^parent /)
      return parents.count > 1
    end
    
    def can_fast_forward_to?(ref)
      # http://stackoverflow.com/a/2934062/167983
      rev_parse_output = GitRunner.run(@repo.path, "rev-parse #{@name}", Verbosity::OUTPUT_NEVER)
      merge_base_output = GitRunner.run(@repo.path, "merge-base \"#{rev_parse_output}\" \"#{ref.name}\"", Verbosity::OUTPUT_NEVER)
      return merge_base_output == rev_parse_output
    end
  end
end

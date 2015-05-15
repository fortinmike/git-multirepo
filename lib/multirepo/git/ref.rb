require_relative "git-runner"

module MultiRepo
  class Ref
    attr_accessor :name
    
    def initialize(repo, name)
      @repo = repo
      @name = name
    end
    
    def hash
      GitRunner.run_in_working_dir(@repo.path, "rev-parse #{@name}", Runner::Verbosity::OUTPUT_NEVER).strip
    end
    
    def is_merge?
      lines = GitRunner.run_in_working_dir(@repo.path, "cat-file -p #{@name}", Runner::Verbosity::OUTPUT_NEVER).split("\n")
      parents = lines.grep(/^parent /)
      return parents.count > 1
    end
    
    def can_fast_forward_to?(ref_name)
      # http://stackoverflow.com/a/2934062/167983
      rev_parse_output = GitRunner.run_in_working_dir(@repo.path, "rev-parse #{@name}", Runner::Verbosity::OUTPUT_NEVER)
      merge_base_output = GitRunner.run_in_working_dir(@repo.path, "merge-base \"#{rev_parse_output}\" \"#{ref_name}\"", Runner::Verbosity::OUTPUT_NEVER)
      return merge_base_output == rev_parse_output
    end
  end
end
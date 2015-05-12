require_relative "git-runner"

module MultiRepo
  class Commit
    attr_accessor :ref
    
    def initialize(repo, ref)
      @repo = repo
      @ref = ref
    end

    def is_merge?
      lines = GitRunner.run_in_working_dir(@repo.path, "cat-file -p #{@ref}", Runner::Verbosity::OUTPUT_NEVER).split("\n")
      parents = lines.grep(/^parent /)
      return parents.count > 1
    end
  end
end
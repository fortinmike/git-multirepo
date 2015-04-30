require_relative "git"

module MultiRepo
  class Commit
    attr_accessor :ref
    
    def initialize(repo, ref)
      @repo = repo
      @ref = ref
    end

    def is_merge?
      lines = Git.run_in_working_dir(@repo.path, "cat-file -p #{@ref}", Runner::Verbosity::NEVER_OUTPUT).split("\n")
      parents = lines.grep(/^parent /)
      return parents.count > 1
    end
  end
end
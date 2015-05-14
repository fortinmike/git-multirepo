require "multirepo/git/repo"

module MultiRepo
  class MergeDescriptor
    attr_accessor :name

    def initialize(name, repo, revision)
      @name = name
      @revision = revision
      @local_branch_name = repo.current_branch.name
      @remote_branch_name = repo.current_branch.remote_branch_name
      @can_ff = repo.current_commit.can_fast_forward_to?(@remote_branch_name)
    end

    def merge_description
      "Merge '#{@revision}' into '#{@local_branch_name}'"
    end

    def upstream_description
      if @can_ff
        "Local branch is outdated"
      else
        "---"
      end
    end
  end
end
require "colored"
require "multirepo/git/repo"

module MultiRepo
  class LocalUpstreamState
    LOCAL_UP_TO_DATE = 0
    LOCAL_OUTDATED = 1
    LOCAL_UPSTREAM_DIVERGED = 2
    LOCAL_NO_UPSTREAM = 3
  end
  
  class MergeDescriptor
    attr_accessor :name
    attr_accessor :upstream_state

    def initialize(name, repo, revision)
      @name = name
      @revision = revision
      
      local_branch = repo.current_branch
      @local_branch_name = local_branch.name
      
      remote_branch = local_branch.remote_branch
      unless remote_branch
        @upstream_state = LocalUpstreamState::LOCAL_NO_UPSTREAM
        return
      end
      
      @upstream_branch_name = remote_branch.name
      
      local_as_upstream = repo.current_commit.hash == repo.current_branch.remote_branch.hash
      can_fast_forward = repo.current_commit.can_fast_forward_to?(@upstream_branch_name)
      
      @upstream_state = if local_as_upstream
        LocalUpstreamState::LOCAL_UP_TO_DATE
      elsif !local_as_upstream && can_fast_forward
        LocalUpstreamState::LOCAL_OUTDATED
      else
        LocalUpstreamState::LOCAL_UPSTREAM_DIVERGED
      end
    end

    def merge_description
      "Merge '#{@revision}' into '#{@local_branch_name}'"
    end

    def upstream_description
      case @upstream_state
      when LocalUpstreamState::LOCAL_UP_TO_DATE; "Local up-to-date with upstream".green
      when LocalUpstreamState::LOCAL_OUTDATED; "Local outdated compared to upstream".yellow
      when LocalUpstreamState::LOCAL_UPSTREAM_DIVERGED; "Local and upstream have diverged!".red
      when LocalUpstreamState::LOCAL_NO_UPSTREAM; "Not remote-tracking".yellow
      end
    end
  end
end
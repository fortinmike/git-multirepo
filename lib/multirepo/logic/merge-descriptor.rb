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
      
      local_branch = repo.branch(revision)
      local = local_branch.exists? ? local_branch : repo.ref(revision)
      @local_name = local.name
      
      upstream = local.instance_of?(Branch) ? local.remote_branch : nil
      unless upstream
        @upstream_state = LocalUpstreamState::LOCAL_NO_UPSTREAM
        return
      end
      
      @upstream_name = upstream.name
      
      local_as_upstream = local.hash == upstream.hash
      can_fast_forward = local.can_fast_forward_to?(upstream.name)
      
      @upstream_state = if local_as_upstream
        LocalUpstreamState::LOCAL_UP_TO_DATE
      elsif !local_as_upstream && can_fast_forward
        LocalUpstreamState::LOCAL_OUTDATED
      else
        LocalUpstreamState::LOCAL_UPSTREAM_DIVERGED
      end
    end

    def merge_description
      "Merge '#{@revision}' into '#{@local_name}'"
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
require "colored"
require "multirepo/git/repo"

module MultiRepo
  class TheirState
    NON_EXISTENT = 0
    EXACT_REF = 1
    LOCAL_NO_UPSTREAM = 2
    UPSTREAM_NO_LOCAL = 3
    LOCAL_UP_TO_DATE = 4
    LOCAL_OUTDATED = 5
    LOCAL_UPSTREAM_DIVERGED = 6
  end
  
  class MergeDescriptor
    attr_accessor :name
    attr_accessor :repo
    attr_accessor :our_revision
    attr_accessor :their_revision
    attr_accessor :state

    def initialize(name, repo, our_revision, their_revision)
      @name = name
      @repo = repo
      @our_revision = our_revision
      @their_revision = their_revision
      
      # Revisions can be anything: "feature1", "origin/feature1", "b51f3c0", ...
      their_ref = repo.ref(their_revision)
      
      @short_commit_id = their_ref.short_commit_id
      
      @state = determine_merge_state(repo, their_ref)
    end
    
    def merge_description
      case @state
      when TheirState::NON_EXISTENT; "No revision named #{@their_revision}".red
      else; "Merge '#{@state == TheirState::EXACT_REF ? @short_commit_id : @their_revision}' into '#{@our_revision}'"
      end
    end

    def upstream_description
      case @state
      when TheirState::NON_EXISTENT; "--"
      when TheirState::EXACT_REF; "Exact ref".yellow
      when TheirState::LOCAL_NO_UPSTREAM; "Not remote-tracking".yellow
      when TheirState::UPSTREAM_NO_LOCAL; "Branch is upstream".green
      when TheirState::LOCAL_UP_TO_DATE; "Local up-to-date with upstream".green
      when TheirState::LOCAL_OUTDATED; "Local outdated compared to upstream".yellow
      when TheirState::LOCAL_UPSTREAM_DIVERGED; "Local and upstream have diverged!".red
      end
    end
    
    private
    
    def determine_merge_state(repo, their_ref)
      return TheirState::NON_EXISTENT unless their_ref.exists?
      
      remote_branch = repo.remote_branches.select{ |b| b.name == their_ref.name }.first
      local_branch = repo.local_branches.select{ |b| b.name == their_ref.name }.first
      
      # If no local branch nor remote branch exist for their_ref, this is an exact ref
      return TheirState::EXACT_REF unless remote_branch || local_branch
      
      # If remote exists but local does not, return UPSTREAM_NO_LOCAL
      return TheirState::UPSTREAM_NO_LOCAL if remote_branch && !local_branch
      
      # If there is no upstream, no need to check for differences between local and remote
      return TheirState::LOCAL_NO_UPSTREAM unless local_branch.upstream_branch
      
      # Else check local vs upstream state
      return determine_local_upstream_merge_state(repo, their_ref)
    end
    
    def determine_local_upstream_merge_state(repo, their_ref)
      # We can assume we're working with a branch at this point
      their_branch = repo.branch(their_ref.name)
      
      their_upstream_branch = their_branch.upstream_branch
      local_as_upstream = their_branch.commit_id == their_upstream_branch.commit_id
      can_fast_forward_local_to_upstream = their_branch.can_fast_forward_to?(their_upstream_branch)
      
      state = if local_as_upstream
        TheirState::LOCAL_UP_TO_DATE
      elsif !local_as_upstream && can_fast_forward_local_to_upstream
        TheirState::LOCAL_OUTDATED
      else
        TheirState::LOCAL_UPSTREAM_DIVERGED
      end
      
      return state
    end
  end
end
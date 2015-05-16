require "colored"
require "multirepo/git/repo"

module MultiRepo
  class TheirState
    NON_EXISTENT = 0
    EXACT_COMMIT = 1
    LOCAL_NO_UPSTREAM = 2
    UPSTREAM_NO_LOCAL = 3
    LOCAL_UP_TO_DATE = 4
    LOCAL_OUTDATED = 5
    LOCAL_UPSTREAM_DIVERGED = 6
  end
  
  class MergeDescriptor
    attr_accessor :name
    attr_accessor :state

    def initialize(name, repo, our_revision, their_revision)
      @name = name
      @our_revision = our_revision
      @their_revision = their_revision
      
      # Reminder: Revisions can be anything:
      # their_revision = "feature1"
      # their_revision = "origin/feature1"
      # their_revision = "b51f3c0"
      
      our_ref = repo.ref(our_revision)
      their_ref = repo.ref(their_revision)
      
      @state = determine_merge_state(our_ref, their_ref)
    end
    
    def merge_description
      case @state
      when TheirState::NON_EXISTENT; "No revision named #{@their_revision}".red
      else; "Merge '#{@their_revision}' into '#{@our_revision}'"
      end
    end

    def upstream_description
      case @state
      when TheirState::NON_EXISTENT; "--"
      when TheirState::EXACT_COMMIT; "Exact commit"
      when TheirState::LOCAL_NO_UPSTREAM; "Not remote-tracking".yellow
      when TheirState::UPSTREAM_NO_LOCAL; "Branch is upstream".green
      when TheirState::LOCAL_UP_TO_DATE; "Local up-to-date with upstream".green
      when TheirState::LOCAL_OUTDATED; "Local outdated compared to upstream".yellow
      when TheirState::LOCAL_UPSTREAM_DIVERGED; "Local and upstream have diverged!".red
      end
    end
    
    private
    
    def determine_merge_state(our_ref, their_ref)
      # TODO: Implement Ref#exists? (does not check for a branch specifically like Branch#exists? does)
      return TheirState::NON_EXISTENT unless their_ref.exists?
      
      # TODO: Check if local branch exists for their_ref (specified ref is a local branch)
      # TODO: Check if remote branch exists for their_ref (specified ref is a remote branch)
      
      # TODO: If no local branch nor remote branch exist, return EXACT_COMMIT
      # TODO: If local exists but remote does not, return LOCAL_NO_UPSTREAM
      # TODO: If remote exists but local does not, return UPSTREAM_NO_LOCAL
      
      # TODO: Else check local vs remote state like we previously did:
      
      # TODO: Find upstream branch for current local branch
      local_as_upstream = their_ref.hash == upstream.hash
      can_fast_forward = local.can_fast_forward_to?(upstream.name)
      
      @state = if local_as_upstream
        TheirState::LOCAL_UP_TO_DATE
      elsif !local_as_upstream && can_fast_forward
        TheirState::LOCAL_OUTDATED
      else
        TheirState::LOCAL_UPSTREAM_DIVERGED
      end
    end
  end
end
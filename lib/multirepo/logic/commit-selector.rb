module MultiRepo
  class CommitSelectionMode
    AS_LOCK = 0
    LATEST = 1
    EXACT = 2
  end
  
  class CommitSelector
    def self.mode_for_args(checkout_latest, checkout_exact)
      if checkout_latest then
        CommitSelectionMode::LATEST
      elsif checkout_exact then
        CommitSelectionMode::EXACT
      else
        CommitSelectionMode::AS_LOCK
      end
    end
    
    def self.ref_for_mode(mode, ref, lock_entry)
      case mode
      when CommitSelectionMode::AS_LOCK; lock_entry.head
      when CommitSelectionMode::LATEST; lock_entry.branch
      when CommitSelectionMode::EXACT; ref
      end
    end
  end
end
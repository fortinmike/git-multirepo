module MultiRepo
  class RevisionSelectionMode
    AS_LOCK = 0
    LATEST = 1
    EXACT = 2
    
    def self.name_for_mode(mode)
      case mode
      when AS_LOCK; "as-lock"
      when LATEST; "latest"
      when EXACT; "exact"
      end
    end
  end
  
  class RevisionSelector
    def self.mode_for_args(checkout_latest, checkout_exact)
      if checkout_latest then
        RevisionSelectionMode::LATEST
      elsif checkout_exact then
        RevisionSelectionMode::EXACT
      else
        RevisionSelectionMode::AS_LOCK
      end
    end
    
    def self.revision_for_mode(mode, ref, lock_entry)
      case mode
      when RevisionSelectionMode::AS_LOCK; lock_entry.head
      when RevisionSelectionMode::LATEST; lock_entry.branch
      when RevisionSelectionMode::EXACT; ref
      end
    end
  end
end
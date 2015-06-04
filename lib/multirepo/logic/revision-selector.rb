module MultiRepo
  class RevisionSelectionMode
    AS_LOCK = 0
    LATEST = 1
    EXACT = 2
    
    def self.name_for_mode(mode)
      case mode
      when AS_LOCK then "as-lock"
      when LATEST then "latest"
      when EXACT then "exact"
      end
    end
  end
  
  class RevisionSelector
    def self.mode_for_args(checkout_latest, checkout_exact)
      if checkout_latest
        RevisionSelectionMode::LATEST
      elsif checkout_exact
        RevisionSelectionMode::EXACT
      else
        RevisionSelectionMode::AS_LOCK
      end
    end
    
    def self.revision_for_mode(mode, ref_name, lock_entry)
      case mode
      when RevisionSelectionMode::AS_LOCK then lock_entry.head
      when RevisionSelectionMode::LATEST then lock_entry.branch
      when RevisionSelectionMode::EXACT then ref_name
      end
    end
  end
end

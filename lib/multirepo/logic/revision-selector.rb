module MultiRepo
  class RevisionSelection
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
        RevisionSelection::LATEST
      elsif checkout_exact
        RevisionSelection::EXACT
      else
        RevisionSelection::AS_LOCK
      end
    end
    
    def self.revision_for_mode(mode, ref_name, lock_entry)
      case mode
      when RevisionSelection::AS_LOCK then lock_entry.head
      when RevisionSelection::LATEST then lock_entry.branch
      when RevisionSelection::EXACT then ref_name
      end
    end
  end
end

require_relative "revision-selection"

module MultiRepo
  class RevisionSelector
    def self.mode_for_args(checkout_latest, checkout_lock)
      if checkout_latest
        RevisionSelection::LATEST
      elsif checkout_lock
        RevisionSelection::AS_LOCK
      else
        RevisionSelection::EXACT
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

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
end

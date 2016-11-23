require "naturally"

module MultiRepo
  class VersionComparer
    def self.is_latest(current:, last:)
      return true if current == last
      return Naturally.sort([current, last]).last == current
    end
  end
end

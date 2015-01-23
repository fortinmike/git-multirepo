require_relative "multirepo/command"
require_relative "multirepo/commands/install"
require_relative "multirepo/commands/fetch"

module MultiRepo
  class MultiRepo
    def self.path
      Gem::Specification.find_by_name("git-multirepo").gem_dir
    end
  end
end
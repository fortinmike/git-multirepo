require "pathname"

require "claide"

require "version"
require "loader"
require "commands/setup"

module MultiRepo
  class Cli
    def self.run(argv)
      CLAide::Command.run(ARGV)
    end
  end
end
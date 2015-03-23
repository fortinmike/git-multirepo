require "open3"
require "multirepo/utility/console"

module MultiRepo
  class Runner
    class Verbosity
      NEVER_OUTPUT = 0
      ALWAYS_OUTPUT = 1
      OUTPUT_ON_ERROR = 2
    end
    
    class << self
      attr_accessor :last_command_succeeded
    end
    
    def self.run(cmd, verbosity)
      lines = []
      Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
        stdout_and_stderr.each do |line|
          Console.log_info(line) if verbosity == Verbosity::ALWAYS_OUTPUT || Config.instance.verbose
          lines << line
        end
        @last_command_succeeded = thread.value.success?
      end
      
      output = lines.join("")
      
      Console.log_error(output) if !@last_command_succeeded && verbosity == Verbosity::OUTPUT_ON_ERROR
      
      return output
    end
  end
end
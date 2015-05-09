require "open3"
require "multirepo/utility/console"

module MultiRepo
  class Runner
    class Verbosity
      OUTPUT_NEVER = 0
      OUTPUT_ALWAYS = 1
      OUTPUT_ON_ERROR = 2
    end
    
    class << self
      attr_accessor :last_command_succeeded
    end
    
    def self.run(cmd, verbosity)
      Console.log_info("Command: #{cmd}") if Config.instance.verbose
      
      lines = []
      Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
        stdout_and_stderr.each do |line|
          Console.log_info("-------> #{line.rstrip}") if verbosity == Verbosity::OUTPUT_ALWAYS || Config.instance.verbose
          lines << line
        end
        @last_command_succeeded = thread.value.success?
      end
      
      output = lines.join("").rstrip
      
      Console.log_error(output) if !@last_command_succeeded && verbosity == Verbosity::OUTPUT_ON_ERROR
      
      return output
    end
  end
end
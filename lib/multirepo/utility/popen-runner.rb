require "open3"

require "multirepo/utility/console"

module MultiRepo
  class PopenRunner
    def self.run(cmd, verbosity)
      Console.log_info("Command: #{cmd}") if Config.instance.verbose
      
      lines = []
      last_command_succeeded = false
      Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
        stdout_and_stderr.each do |line|
          print line if Config.instance.verbose
          lines << line
        end
        last_command_succeeded = thread.value.success?
      end
      
      output = lines.join("").rstrip
      
      Console.log_error(output) if !last_command_succeeded && verbosity == Verbosity::OUTPUT_ON_ERROR
      
      return output, last_command_succeeded
    end
  end
end
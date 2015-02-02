require "open3"

module MultiRepo
  class Runner
    class << self
      attr_accessor :last_command_succeeded
    end
    
    def self.run(cmd, show_output)
      output = []
      Open3.popen2e(cmd) do |stdin, stdout_and_stderr, thread|
        stdout_and_stderr.each do |line|
          puts line if show_output
          output << line
        end
        @last_command_succeeded = thread.value.success?
      end
      output.join("")
    end
  end
end
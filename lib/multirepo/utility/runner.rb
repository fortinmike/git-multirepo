require "open3"

module MultiRepo
  class Runner
    class << self
      attr_accessor :last_command_succeeded
    end
    
    def self.run(cmd, show_output)
      output = []
      Open3.popen3(cmd) do |stdin, stdout, stderr, thread|     
        # STDOUT
        Thread.new do
          until (line = stdout.gets).nil? do
            output << line
            puts line if show_output
          end
        end
        
        # STDERR
        Thread.new do
          until (line = stderr.gets).nil? do
            output << line
            puts line.red if show_output
          end
        end
        
        thread.join # don't exit until the external process is done
        @last_command_succeeded = thread.value.success?
      end
      
      return output.join("")
    end
  end
end
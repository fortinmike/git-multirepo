module MultiRepo
  class Runner
    def self.run(cmd)
      return run_internal(cmd, false)
    end
    
    def self.run_with_output(cmd)
      return run_internal(cmd, true)
    end
    
    def self.run_internal(cmd, output_to_console)
      output = []
      IO.popen(cmd).each do |line|
        puts line if output_to_console
        output << line
      end.close
      return output.join('')
    end
  end
end
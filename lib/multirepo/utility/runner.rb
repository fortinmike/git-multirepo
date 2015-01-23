module MultiRepo
  class Runner
    def self.run(cmd, show_output)
      output = []
      IO.popen(cmd).each do |line|
        puts line if show_output
        output << line
      end.close
      return output.join('')
    end
  end
end
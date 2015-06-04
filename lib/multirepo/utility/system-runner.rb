require "multirepo/utility/console"

module MultiRepo
  class SystemRunner
    def self.run(cmd)
      Console.log_info("Command: #{cmd}") if Config.instance.verbose
      
      output = system(cmd)
      last_command_succeeded = ($CHILD_STATUS.exitstatus == 0)
      
      return output, last_command_succeeded
    end
  end
end

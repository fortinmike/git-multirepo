require "multirepo/git/git-runner"

module MultiRepo
  class Git
    def self.valid_branch_name?(name)
      GitRunner.run(".", "check-ref-format --branch \"#{name}\"", Runner::Verbosity::OUTPUT_NEVER)
      GitRunner.last_command_succeeded
    end
  end
end
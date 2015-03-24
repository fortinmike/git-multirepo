require "multirepo/utility/console"
require "multirepo/files/config-file"

module MultiRepo
  class BranchCommand < Command
    self.command = "branch"
    self.summary = "Create and/or checkout a new branch for all repos."
    
    def self.options
      [
        ['[branch name]', 'The name of the branch to create and checkout.'],
        ['--force', 'Force creating the branch even if the repos contain uncommmitted changes.'],
        ['--no-track', 'Do not configure as a remote-tracking branch on creation.']
      ].concat(super)
    end
    
    def initialize(argv)
      @branch_name = argv.shift_argument
      @force = argv.flag?("force")
      @remote_tracking = !argv.flag?("no-track")
      super
    end
    
    def validate!
      super
      help! "You must specify a branch name" unless @branch_name
    end
    
    def run
      super
      ensure_multirepo_initialized
      
      Console.log_step("Branching and checking out #{@branch_name}...")
      
      main_repo = main_repo = Repo.new(".")
      repos = ConfigFile.load.map{ |entry| entry.repo }.push(main_repo)
      
      if !Utils.ensure_working_copies_clean(repos) && !@force
        raise MultiRepoException, "Can't branch because not all repos are clean"
      end

      repos.each do |repo|
        branch = repo.branch(@branch_name)
        branch.create(remote_tracking: @remote_tracking) unless branch.exists?
        branch.checkout
      end

      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
require "multirepo/utility/console"
require "multirepo/files/config-file"

module MultiRepo
  class BranchCommand < Command
    self.command = "branch"
    self.summary = "Create and/or checkout a new branch for each dependency."
    
    def initialize(argv)
      @branch_name = argv.shift_argument
      super
    end
    
    def validate!
      super
      help! "You must specify a branch name" unless @branch_name
    end
    
    def run
      super
      ensure_multirepo_initialized

      Console.log_step("Branching (\"#{@branch_name}\")...")

      main_repo = main_repo = Repo.new(".")
      repos = ConfigFile.load.map{ |entry| entry.repo }.push(main_repo)

      unless ensure_working_copies_clean(repos)
        raise MultiRepoException, "Can't branch because not all repos are clean"
      end

      repos.each do |repo|
        branch = repo.branch(@branch_name)
        branch.create unless branch.exists?
        branch.checkout
      end
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end

    def ensure_working_copies_clean(repos)
      repos.all? do |repo|
        clean = repo.is_clean?
        Console.log_warning("Repo #{entry.path} has uncommitted changes") unless clean
        return clean
      end
    end
  end
end
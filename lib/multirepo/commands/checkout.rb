require "multirepo/utility/console"

module MultiRepo
  class Checkout < Command
    self.command = "checkout"
    self.summary = "Checks out the specified commit or branch in the main repo and checks out matching versions of all dependencies."
    
    def initialize(argv)
      @ref = argv.shift_argument
      @checkout_latest = argv.flag?("latest")
      super
    end
    
    def run
      super
      ensure_multirepo_initialized
      
      config_entries = ConfigFile.load_entries
      
      main_repo = Repo.new(".")
      all_repos = config_entries.map{ |e| e.repo }.push(main_repo)
      if all_repos.any? { |r| r.changes.count > 0 }
        raise "Can't checkout #{@ref} because some repositories have uncommitted changes"
      end
      
      Console.log_step("Checking out #{@ref}...")
      
      unless main_repo.checkout(@ref)
        Console.log_error("Couldn't check out #{@ref} in main project!")
        return
      end
      
      Console.log_substep("Checked out #{@ref} of main repo")
      
      LockFile.load_entries.each do |lock_entry|
        config_entry = config_entries.select{ |config_entry| config_entry.id == lock_entry.id }.first
        revision = @checkout_latest ? lock_entry.branch : lock_entry.head
        if config_entry.repo.checkout(revision)
          Console.log_substep("Checked out #{revision} of #{lock_entry.name}")
        else
          Console.log_error("Couldn't check out the appropriate version of dependency #{lock_entry.name}")
        end
      end
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
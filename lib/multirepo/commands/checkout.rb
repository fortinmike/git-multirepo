require "multirepo/utility/console"

module MultiRepo
  class Checkout < Command
    self.command = "checkout"
    self.summary = "Checks out the specified commit or branch of the main repo and checks out matching versions of all dependencies."
    
    def initialize(argv)
      @ref = argv.shift_argument
      @checkout_latest = argv.flag?("latest")
      super
    end
    
    def run
      super
      ensure_multirepo_initialized
      
      main_repo = Repo.new(".")
      initial_revision = main_repo.current_branch || main_repo.head_hash
                  
      Console.log_step("Checking out #{@ref} and its dependencies...")
      
      unless main_repo.is_clean?
        raise "Can't checkout #{@ref} because the main repo contains uncommitted changes"
      end
      
      unless main_repo.checkout(@ref)
        raise MultiRepoException, "Couldn't perform checkout of main repo #{@ref}!"
      end
      
      Console.log_substep("Checked out main repo #{@ref}")
      
      unless LockFile.exists?
        main_repo.checkout(initial_revision)
        raise MultiRepoException, "The specified revision was not managed by multirepo. Checkout reverted."
      end
      
      if Utils.warn_of_uncommitted_changes(ConfigFile.load)
        main_repo.checkout(initial_revision)
        raise "#{e.path} contains uncommitted changes. Checkout reverted."
      end
      
      config_entries = ConfigFile.load # Load the post-checkout config entries, which might be different than pre-checkout
      LockFile.load.each do |lock_entry|
        config_entry = config_entries.select{ |config_entry| config_entry.id == lock_entry.id }.first
        revision = @checkout_latest ? lock_entry.branch : lock_entry.head
        if config_entry.repo.checkout(revision)
          Console.log_substep("Checked out #{lock_entry.name} #{revision}")
        else
          raise MultiRepoException, "Couldn't check out the appropriate version of dependency #{lock_entry.name}"
        end
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
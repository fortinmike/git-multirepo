require "multirepo/utility/console"

module MultiRepo
  class CheckoutCommand < Command
    self.command = "checkout"
    self.summary = "Checks out the specified commit or branch of the main repo and checks out matching versions of all dependencies."
    
    def initialize(argv)
      @ref = argv.shift_argument
      @checkout_latest = argv.flag?("latest")
      @checkout_exact = argv.flag?("exact")
      super
    end
    
    def validate!
      super
      help! "You must specify a branch or commit id to checkout" unless @ref
      help! "You can't provide more than one operation modifier (--latest, --exact, etc.)" if @checkout_latest && @checkout_exact
    end
    
    def run
      super
      ensure_multirepo_initialized
      
      main_repo = Repo.new(".")
      initial_revision = main_repo.current_branch || main_repo.head_hash
                  
      Console.log_step("Checking out #{@ref} and its dependencies...")
      
      unless main_repo.is_clean?
        raise MultiRepoException, "Can't checkout #{@ref} because the main repo contains uncommitted changes"
      end
      
      unless main_repo.checkout(@ref)
        raise MultiRepoException, "Couldn't perform checkout of main repo #{@ref}!"
      end
      
      Console.log_substep("Checked out main repo #{@ref}")
      
      unless LockFile.exists?
        main_repo.checkout(initial_revision)
        raise MultiRepoException, "The specified revision was not managed by multirepo. Checkout reverted."
      end
      
      if Utils.check_for_uncommitted_changes(ConfigFile.load)
        main_repo.checkout(initial_revision)
        raise MultiRepoException, "'#{e.path}' contains uncommitted changes. Checkout reverted."
      end
      
      config_entries = ConfigFile.load # Load the post-checkout config entries, which might be different than pre-checkout
      LockFile.load.each do |lock_entry|
        config_entry = config_entries.select{ |config_entry| config_entry.id == lock_entry.id }.first
        revision = @checkout_latest ? lock_entry.branch : lock_entry.head
        revision = @checkout_exact ? @ref : revision
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
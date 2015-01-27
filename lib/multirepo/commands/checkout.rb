require "multirepo/utility/console"

module MultiRepo
  class Checkout < Command
    self.command = "checkout"
    self.summary = "Checks out the specified commit or branch in the main repo and checks out matching versions of all dependencies."
    
    def initialize(argv)
      @ref = argv.shift_argument
      super
    end
    
    def run
      super
      ensure_multirepo_initialized
      Console.log_step("Checking out #{@ref}...")
      
      main_repo = Repo.new(".")
      if main_repo.checkout(@ref)
        Console.log_error("Couldn't check out main project revision #{@ref}!")
        return
      end
      
      Console.log_substep("Checked out revision #{@ref} of main repo")
      
      LockFile.load_entries.each do |e|
        if e.repo.checkout(e.head_hash)
          Console.log_substep("Checked out revision #{e.head_hash} of dependency #{e.folder_name}")
        else
          Console.log_error("Couldn't check out the appropriate revision of dependency #{e.folder_name}")
        end
      end
      
      Console.log_step("Done!")
    rescue Exception => e
      Console.log_error(e.message)
    end
  end
end
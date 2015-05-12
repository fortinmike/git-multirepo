require "multirepo/utility/console"

module MultiRepo
  class CleanCommand < Command
    self.command = "clean"
    self.summary = "Performs a 'git clean -df' on the main repo and all dependencies."
    
    def run
      super
      ensure_in_work_tree
      ensure_multirepo_enabled
      
      Console.log_step("Fetching dependencies...")
      
      Console.log_substep("Cleaning main repo...")
      clean(".")
      
      ConfigFile.new(".").load_entries.each do |entry|
        Console.log_substep("Cleaning #{entry.repo.path} ...")
        clean(entry.repo.path)
      end
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
    
    def clean(repo_path)
      GitRunner.run_in_working_dir(repo_path, "clean -df", Runner::Verbosity::OUTPUT_ALWAYS)
    end
  end
end
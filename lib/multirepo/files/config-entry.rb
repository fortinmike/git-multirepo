require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class ConfigEntry
    attr_accessor :folder_name
    attr_accessor :repo
    
    def to_s
      "#{@folder_name} #{@remote_url} #{@branch_name}"
    end
    
    def initialize(*args)
      if args.length == 1
        self.initialize_with_repo(*args)
      elsif args.length == 3
        self.initialize_with_args(*args)
      else
        raise "Wrong number of arguments in ConfigEntry.new() call"
      end
    end
    
    def initialize_with_repo(repo)
      @folder_name = repo.working_copy_basename
      @repo = repo
      @remote_url = repo.remote('origin').url
      @branch_name = repo.current_branch
    end
    
    def initialize_with_args(folder_name, remote_url, branch_name)
      @folder_name = folder_name
      @repo = Repo.new("../#{folder_name}")
      @remote_url = remote_url
      @branch_name = branch_name
    end
    
    def install
      if @repo.exists?
        check_repo_validity
        fetch_repo
      else
        clone_repo
      end
      checkout_branch
    end
    
    def exists?
      ConfigFile::FILE.open("r").each_line do |line|
        return true if line.start_with?(@folder_name)
      end
      false
    end
    
    # Repo operations
    
    def fetch_repo
      Console.log_substep("Working copy #{@repo.working_copy} already exists, fetching instead...")
      if !@repo.fetch then raise "Could not fetch from remote #{@repo.remote('origin').url}"
      end
    end
    
    def clone_repo
      Console.log_substep("Cloning #{@remote_url} to #{@repo.working_copy}")
      if !@repo.clone(@remote_url) then raise "Could not clone remote #{@remote_url}" end
    end
    
    def checkout_branch
      branch = @repo.branch(@branch_name);
      
      unless branch.exists?
        Console.log_warning("Branch #{@branch_name} doesn't exist in working copy #{@repo.working_copy}")
        return
      end
      
      if branch.checkout
        Console.log_info("Checked out branch #{branch.name} -> origin/#{branch.name}")
      else
        raise "Could not setup branch #{branch.name}"
      end
    end
    
    # Validation
    
    def check_repo_validity
      unless remote_matches_entry
        raise "#{@folder_name} origin URL (#{@repo.remote('origin').url}) does not match entry (#{@remote_url})!"
      end
    end
    
    def remote_matches_entry
      @repo.remote("origin").url == @remote_url
    end
  end
end
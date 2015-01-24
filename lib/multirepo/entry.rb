require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class Entry
    attr_accessor :folder_name
    attr_accessor :repo
    
    def initialize(*args)
      if args.length == 1
        self.initialize_with_repo(*args)
      elsif args.length == 3
        self.initialize_with_args(*args)
      else
        raise "Wrong number of arguments in Entry.new() call"
      end
    end
    
    def initialize_with_repo(repo)
      @folder_name = Pathname.new(repo.working_copy).basename.to_s
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
      Config::FILE.open("r").each_line do |line|
        return true if line.start_with?(@folder_name)
      end
      false
    end
    
    def add
      entry_string = "#{@folder_name} #{@remote_url} #{@branch_name}"
      Config::FILE.open("a") { |f| f.puts entry_string }
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
      
      if !branch.exists? && branch.create(remote_tracking: true)
        Console.log_info("Created branch #{branch.name}")
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
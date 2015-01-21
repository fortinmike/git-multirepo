require_relative "git"
require_relative "console"

module MultiRepo
  class Repo
    attr_accessor :folder_name
    attr_accessor :remote_url
    attr_accessor :branch_name
    
    def initialize(folder_name, remote_url, branch_name)
      @folder_name = folder_name
      @working_copy = "../#{folder_name}"
      @remote_url = remote_url
      @branch_name = branch_name
    end
    
    def exists?
      Dir.exist?("#{@working_copy}/.git")
    end
    
    def checkout
      if exists?
        # TODO: Check if the existing repo's origin matches the expected remote
        MultiRepo::Console.log_warning("Working copy #{@working_copy} already exists, fetching instead...")
        fetch
      else
        MultiRepo::Console.log_substep("Cloning #{@remote_url} to #{@working_copy}")
        clone
      end
    end
    
    def fetch
      MultiRepo::Git.run(@working_copy, "fetch", true)
    end
    
    def clone
      MultiRepo::Git.run("clone #{@remote_url} #{@working_copy}", true)
    end
  end
end
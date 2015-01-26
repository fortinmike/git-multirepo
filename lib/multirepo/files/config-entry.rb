require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class ConfigEntry
    attr_accessor :folder_name
    attr_accessor :remote_url
    attr_accessor :branch_name
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
      @repo = repo
      
      @folder_name = repo.working_copy_basename
      @remote_url = repo.remote('origin').url
      @branch_name = repo.current_branch
    end
    
    def initialize_with_args(folder_name, remote_url, branch_name)
      @folder_name = folder_name
      @remote_url = remote_url
      @branch_name = branch_name
      
      @repo = Repo.new("../#{folder_name}")
    end
  end
end
require "securerandom"

require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class ConfigEntry
    attr_accessor :id
    attr_accessor :path
    attr_accessor :remote_url
    attr_accessor :branch_name
    attr_accessor :repo
    
    def to_s
      "#{@id}, #{@path}, #{@remote_url}, #{@branch_name}"
    end
    
    def initialize(*args)
      if args.length == 1
        self.initialize_with_repo(*args)
      elsif args.length == 4
        self.initialize_with_args(*args)
      else
        raise "Wrong number of arguments in ConfigEntry.new() call"
      end
    end
    
    def initialize_with_repo(repo)
      @id = SecureRandom.uuid
      @path = repo.path
      @remote_url = repo.remote('origin').url
      @branch_name = repo.current_branch
    end
    
    def initialize_with_args(id, path, remote_url, branch_name)
      @id = id
      @path = path
      @remote_url = remote_url
      @branch_name = branch_name
    end
    
    def repo
      Repo.new(path)
    end
  end
end
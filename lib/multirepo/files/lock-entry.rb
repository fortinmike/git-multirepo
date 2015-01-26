require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class LockEntry
    attr_accessor :folder_name
    attr_accessor :head_hash
    
    def to_s
      "#{@folder_name} #{@head_hash}"
    end
    
    def initialize(*args)
      if args.length == 1
        self.initialize_with_repo(*args)
      elsif args.length == 2
        self.initialize_with_args(*args)
      else
        raise "Wrong number of arguments in LockEntry.new() call"
      end
    end
    
    def initialize_with_repo(repo)
      @folder_name = repo.working_copy_basename
      @head_hash = repo.head_hash
    end
    
    def initialize_with_args(folder_name, head_hash)
      @folder_name = folder_name
      @head_hash = head_hash
    end
  end
end
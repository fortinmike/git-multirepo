require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class LockEntry
    attr_accessor :folder_name
    attr_accessor :head_hash
    attr_accessor :branch_name
    
    def repo
      Repo.new("../#{folder_name}")
    end
    
    def encode_with(coder)
      coder["name"] = @folder_name
      coder["head"] = @head_hash
      coder["branch"] = @branch_name
    end
    
    def initialize(repo)
      @folder_name = repo.working_copy_basename
      @head_hash = repo.head_hash
      @branch_name = repo.current_branch
    end
  end
end
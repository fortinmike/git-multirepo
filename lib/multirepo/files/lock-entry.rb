require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class LockEntry
    attr_accessor :config_entry
    attr_accessor :name
    attr_accessor :id
    attr_accessor :head
    attr_accessor :branch_name
    
    def repo
      Repo.new("../#{folder_name}")
    end
    
    def encode_with(coder)
      coder["name"] = @name
      coder["id"] = @id
      coder["head"] = @head
      coder["branch"] = @branch_name
    end
    
    def initialize(config_entry)
      @name = config_entry.repo.basename
      @id = config_entry.id
      @head = config_entry.repo.head_hash
      @branch_name = config_entry.repo.current_branch
    end
  end
end
require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class LockEntry
    attr_accessor :name
    attr_accessor :id
    attr_accessor :head
    attr_accessor :branch
    
    def encode_with(coder)
      coder["name"] = @name
      coder["id"] = @id
      coder["head"] = @head
      coder["branch"] = @branch
    end
    
    def initialize(config_entry)
      @name = config_entry.repo.basename
      @id = config_entry.id
      @head = config_entry.repo.head_hash
      @branch = config_entry.repo.current_branch
    end
  end
end
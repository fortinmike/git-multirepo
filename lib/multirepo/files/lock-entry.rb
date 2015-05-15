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
      @name = config_entry.name
      @id = config_entry.id
      @head = config_entry.repo.head.hash
      
      current_branch = config_entry.repo.current_branch
      @branch = current_branch ? current_branch.name : nil
    end
  end
end
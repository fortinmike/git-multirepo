require "securerandom"

require "multirepo/utility/console"
require "multirepo/git/repo"

module MultiRepo
  class ConfigEntry
    attr_accessor :id
    attr_accessor :path
    attr_accessor :url
    attr_accessor :repo
    
    def encode_with(coder)
      coder["id"] = @id
      coder["path"] = @path
      coder["url"] = @url
    end
    
    def initialize(repo)
      @id = SecureRandom.uuid
      @path = repo.path
      @url = repo.exists? ? repo.remote('origin').url : nil
    end
    
    def ==(entry)
      entry_path = Pathname.new(entry.path)
      self_path = Pathname.new(self.path)
      entry_path.exist? && self_path.exist? && entry_path.realpath == self_path.realpath
    end
    
    def repo
      Repo.new(path)
    end
    
    def name
      repo.basename
    end
  end
end
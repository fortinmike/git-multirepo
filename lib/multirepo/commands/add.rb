require "claide"

require "multirepo/utility/console"
require "multirepo/config"

module MultiRepo
  class Add < Command
    self.command = "add"
    self.summary = "Add a repository to the .multirepo file."
    
    def initialize(argv)
      @repo = Repo.new("../#{argv.shift_argument}")
      super
    end
    
    def run
      super
      check_repo_exists
      Config.create unless Config.exists?
      Config.add(@repo)
    rescue Exception => e
      Console.log_error(e.message)
    end
    
    def check_repo_exists
      if !Dir.exists?(@repo.working_copy) then raise "There is no folder at path #{@repo.working_copy}" end
      if !@repo.exists? then raise "#{@repo.working_copy} is not a repository" end
    end
  end
end
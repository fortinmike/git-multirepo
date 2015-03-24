require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"

module MultiRepo
  class CloneCommand < Command
    self.command = "clone"
    self.summary = "Clones the specified repository in a subfolder, then installs it."
    
    def self.options
      [
        ['[url]', 'The repository to clone.'],
        ['[name]', 'The name of the containing folder that will be created.']
      ].concat(super)
    end
    
    def initialize(argv)
      @url = argv.shift_argument
      @name = argv.shift_argument
      super
    end

    def validate!
      super
      help! "You must specify a repository to clone" unless @url
      help! "You must specify a containing folder name" unless @name
    end

    def run
      Console.log_step("Cloning #{url} ...")

      raise MultiRepoException, "A directory named #{@name} already exists" if Dir.exists?(@name)

      main_repo_path = "#{@name}/#{@name}"

      FileUtils.mkpath(main_repo_path)

      main_repo = Repo.new(main_repo_path)
      main_repo.clone(@url)

      # TODO: Perform a multi install in the target main repo directory
            
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
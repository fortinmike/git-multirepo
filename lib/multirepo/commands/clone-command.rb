require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"
require_relative "install-command"

module MultiRepo
  class CloneCommand < Command
    self.command = "clone"
    self.summary = "Clones the specified repository in a subfolder, then installs it."
    
    def self.options
      [
        ['[url]', 'The repository to clone.'],
        ['[name]', 'The name of the containing folder that will be created.'],
        ['[ref]', 'The branch, tag or commit id to checkout. Checkout will use "master" if unspecified.']
      ].concat(super)
    end
    
    def initialize(argv)
      @url = argv.shift_argument
      @name = argv.shift_argument
      @ref = argv.shift_argument
      super
    end

    def validate!
      super
      help! "You must specify a repository to clone" unless @url
      help! "You must specify a containing folder name" unless @name
    end

    def run
      Console.log_step("Cloning #{@url} ...")

      raise MultiRepoException, "A directory named #{@name} already exists" if Dir.exists?(@name)

      main_repo_path = "#{@name}/#{@name}"

      FileUtils.mkpath(main_repo_path)

      main_repo = Repo.new(main_repo_path)
      raise MultiRepoException, "Could not clone repo from #{@url}" unless main_repo.clone(@url)
      
      original_path = Dir.pwd
      Dir.chdir(main_repo_path)
      
      install_command = InstallCommand.new(CLAide::ARGV.new([]))
      install_command.install_dependencies_step(@ref)
      
      Dir.chdir(original_path)
            
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
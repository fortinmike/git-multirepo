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
        ['<url>', 'The repository to clone.'],
        ['<name>', 'The name of the containing folder that will be created.'],
        ['[<refname>]', 'The branch, tag or commit id to checkout. Checkout will use "master" if unspecified.']
      ].concat(super)
    end
    
    def initialize(argv)
      @url = argv.shift_argument
      @name = argv.shift_argument
      @ref_name = argv.shift_argument || "master"
      super
    end

    def validate!
      super
      help! "You must specify a repository to clone" unless @url
      help! "You must specify a containing folder name" unless @name
    end

    def run
      super
      Console.log_step("Cloning #{@url} ...")

      raise MultiRepoException, "A directory named #{@name} already exists" if Dir.exists?(@name)

      main_repo_path = "#{@name}/#{@name}"
      main_repo = Repo.new(main_repo_path)
      
      # Recursively create the directory where we'll clone the main repo
      FileUtils.mkpath(main_repo_path)
      
      # Clone the specified remote in the just-created directory
      raise MultiRepoException, "Could not clone repo from #{@url}" unless main_repo.clone(@url)
      
      # Checkout the specified main repo ref so that install reads the proper config file
      unless main_repo.checkout(@ref_name)
        raise MultiRepoException, "Couldn't perform checkout of main repo #{@ref_name}!"
      end
      
      Console.log_substep("Checked out main repo #{@ref_name}")
      
      # Make sure the ref we just checked out is tracked by multirepo
      unless Utils.is_multirepo_tracked(main_repo_path)
        raise MultiRepoException, "Ref #{@ref_name} is not tracked by multirepo"
      end
      
      # Install
      original_path = Dir.pwd
      Dir.chdir(main_repo_path)
      install_command = InstallCommand.new(CLAide::ARGV.new([]))
      install_command.full_install
      Dir.chdir(original_path)
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end
  end
end
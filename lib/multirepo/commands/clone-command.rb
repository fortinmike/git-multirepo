require "multirepo/utility/console"
require "multirepo/utility/utils"
require "multirepo/git/repo"

module MultiRepo
  class CloneCommand < Command
    self.command = "clone"
    self.summary = "Clones the specified repository in a subfolder, then installs it."
    
    def self.options
      [
        ['[uri]', 'The repository to clone.']
        ['[name]', 'The name of the containing folder that will be created. If unspecified, will be derived from the specified URL.']
      ].concat(super)
    end
    
    def initialize(argv)
      @uri = argv.shift_argument
      @name = argv.shift_argument
      super
    end

    def validate!
      super
      help! "You must specify a repository to clone" unless @url
    end

    def run
      super
      Console.log_step("Cloning...")

      puts name_from_uri(@uri)
      #Dir.mkdir(@name || name_from_uri(@uri))
      
      self.install_pre_commit_hook
      
      Console.log_step("Done!")
    rescue MultiRepoException => e
      Console.log_error(e.message)
    end

    def name_from_url(uri)
      URI(uri).path.split('/').last
    end
  end
end
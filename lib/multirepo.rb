require_relative "multirepo/commands/command"
require_relative "multirepo/commands/init"
require_relative "multirepo/commands/install"
require_relative "multirepo/commands/fetch"
require_relative "multirepo/commands/add"
require_relative "multirepo/commands/open"

module MultiRepo
  class MultiRepo
    def self.path_for_resource(resource_name)
      gem_path = Gem::Specification.find_by_name("git-multirepo").gem_dir
      File.join(gem_path, "resources/#{resource_name}")
    end
    
    def self.install_pre_commit_hook
      FileUtils.cp(path_for_resource("pre-commit"), ".git/hooks")
    end
    
    def self.sibling_repos
      sibling_directories = Dir['../*/']
      sibling_repos = sibling_directories.map{ |d| Repo.new(d) }.select{ |r| r.exists? }
      sibling_repos.delete_if{ |r| Pathname.new(r.working_copy).realpath == Pathname.new(".").realpath }
    end
  end
end
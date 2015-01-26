require "fileutils"

module MultiRepo
  class Utils
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
    
    def self.check_for_uncommited_changes(config_entries)
      uncommited = false
      config_entries.each do |e|
        next unless e.repo.exists?
        if e.repo.has_uncommited_changes
          Console.log_warning("Repository #{e.repo.working_copy} has uncommited changes")
          uncommited = true
        end
      end
      return uncommited
    end
  end
end
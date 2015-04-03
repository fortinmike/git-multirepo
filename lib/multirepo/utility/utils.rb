require "fileutils"

module MultiRepo
  class Utils
    def self.path_for_resource(resource_name)
      gem_path = Gem::Specification.find_by_name("git-multirepo").gem_dir
      File.join(gem_path, "resources/#{resource_name}")
    end
    
    def self.is_multirepo_enabled(path)
      File.exists?(File.join(path, ".multirepo")) &&
      File.exists?(File.join(path, ".multirepo.lock"))
    end
    
    def self.install_hook(name, path)
      FileUtils.cp(path_for_resource(name), File.join(path, ".git/hooks"))
    end
    
    def self.sibling_repos
      sibling_directories = Dir['../*/']
      sibling_repos = sibling_directories.map{ |d| Repo.new(d) }.select{ |r| r.exists? }
      sibling_repos.delete_if{ |r| Pathname.new(r.path).realpath == Pathname.new(".").realpath }
    end
    
    def self.ensure_dependencies_clean(config_entries)
      clean = true
      config_entries.each do |e|
        next unless e.repo.exists?
        dependency_clean = e.repo.is_clean?
        clean &= dependency_clean
        Console.log_info("Dependency '#{e.repo.path}' is clean") if dependency_clean
        Console.log_warning("Dependency '#{e.repo.path}' contains uncommitted changes") unless dependency_clean
      end
      return clean
    end
    
    def self.ensure_working_copies_clean(repos)
      clean = true
      repos.each do |repo|
        dependency_clean = e.repo.is_clean?
        clean &= dependency_clean
        Console.log_warning("Repo '#{repo.path}' contains uncommitted changes") unless dependency_clean
      end
      return clean
    end

    def self.convert_to_windows_path(unix_path)
      components = Pathname.new(unix_path).each_filename.to_a
      components.join(File::ALT_SEPARATOR)
    end
  end
end
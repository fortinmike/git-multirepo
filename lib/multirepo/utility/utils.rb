require "fileutils"

module MultiRepo
  class Utils
    def self.path_for_resource(resource_name)
      gem_path = Gem::Specification.find_by_name("git-multirepo").gem_dir
      File.join(gem_path, "resources/#{resource_name}")
    end
    
    def self.is_multirepo_enabled(path)
      File.exists?(File.join(path, ".multirepo"))
    end

    def self.is_multirepo_tracked(path)
      is_multirepo_enabled(path) && File.exists?(File.join(path, ".multirepo.lock"))
    end
    
    def self.install_hook(name, path)
      destination_path = File.join(path, ".git/hooks")
      destination_file = File.join(destination_path, name)
      FileUtils.cp(path_for_resource(name), destination_file)
      FileUtils.chmod(0755, destination_file) # -rwxr-xr-x
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
        Console.log_warning("Dependency '#{e.repo.path}' contains uncommitted changes") unless dependency_clean
      end
      return clean
    end
    
    def self.ensure_working_copies_clean(repos)
      clean = true
      repos.each do |repo|
        dependency_clean = repo.is_clean?
        clean &= dependency_clean
        Console.log_warning("Repo '#{repo.path}' contains uncommitted changes") unless dependency_clean
      end
      return clean
    end

    def self.convert_to_windows_path(unix_path)
      components = Pathname.new(unix_path).each_filename.to_a
      components.join(File::ALT_SEPARATOR)
    end
    
    def self.reveal_in_default_file_browser(unix_path)
      if OS.osx?
        system %{open "#{unix_path}"}
      elsif OS.windows?
        system %{explorer "#{Utils.convert_to_windows_path(unix_path)}"}
      end
    end
    
    def self.open_in_default_app(unix_path)
      if OS.osx?
        system %{open "#{unix_path}"}
      elsif OS.windows?
        system %{cmd /c "start C:\\#{Utils.convert_to_windows_path(unix_path)}"}
      end
    end
    
    def self.append_if_missing(path, pattern, string_to_append)
      unless File.exists?(path)
        File.open(path, 'w') { |f| f.puts(string_to_append) }
      else
        string_located = File.readlines(path).grep(pattern).any?
        File.open(path, 'a') { |f| f.puts(string_to_append) } unless string_located
      end
    end
  end
end
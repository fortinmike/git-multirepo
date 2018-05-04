require "multirepo/multirepo-exception"
require "fileutils"

module MultiRepo
  class Utils
    def self.standard_path(p)
      path = URI.parse(p).path
      path.insert(0, '/') if (path[0] != '/')
      path.chomp!('/') if (path > '/')
      path
    end

    def self.only_one_true?(*flags)
      flags.reduce(0) { |count, flag| count += 1 if flag; count } <= 1
    end

    def self.path_for_resource(resource_name)
      gem_path = Gem::Specification.find_by_name("git-multirepo").gem_dir
      File.join(gem_path, "resources/#{resource_name}")
    end
    
    def self.multirepo_enabled?(path)
      File.exist?(File.join(path, ".multirepo"))
    end

    def self.multirepo_tracked?(path)
      multirepo_enabled?(path) && File.exist?(File.join(path, ".multirepo.lock"))
    end
    
    def self.install_hook(name, path)
      destination_path = File.join(path, ".git/hooks")
      destination_file = File.join(destination_path, name)
      FileUtils.cp(path_for_resource(name), destination_file)
      FileUtils.chmod(0755, destination_file) # -rwxr-xr-x
    end
    
    def self.sibling_repos
      sibling_directories = Dir['../*/']
      sibling_repos = sibling_directories.map{ |d| Repo.new(d) }.select(&:exists?)
      sibling_repos.delete_if{ |r| Pathname.new(r.path).realpath == Pathname.new(".").realpath }
    end
    
    def self.dependencies_clean?(config_entries)
      clean = true
      missing = false
      config_entries.each do |e|
        # Ensure the dependency exists
        unless e.repo.exists?
          Console.log_error("Dependency '#{e.path}' does not exist on disk")
          missing |= true
          next
        end
        
        # Ensure it contains no uncommitted changes
        dependency_clean = e.repo.clean?
        clean &= dependency_clean
        Console.log_warning("Dependency '#{e.repo.path}' contains uncommitted changes") unless dependency_clean
      end
      
      fail MultiRepoException, "Some dependencies are not present on this machine." \
        " Run \"multi install\" to clone missing dependencies." if missing
      
      return clean
    end
    
    def self.ensure_working_copies_clean(repos)
      clean = true
      repos.each do |repo|
        dependency_clean = repo.clean?
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
        system %(open "#{unix_path}")
      elsif OS.windows?
        system %(explorer "#{Utils.convert_to_windows_path(unix_path)}")
      end
    end
    
    def self.open_in_default_app(unix_path)
      if OS.osx?
        system %(open "#{unix_path}")
      elsif OS.windows?
        system %(cmd /c "start C:\\#{Utils.convert_to_windows_path(unix_path)}")
      end
    end
    
    def self.append_if_missing(path, pattern, string_to_append)
      if File.exist?(path)
        string_located = File.readlines(path).grep(pattern).any?
        File.open(path, 'a') { |f| f.puts(string_to_append) } unless string_located
      else
        File.open(path, 'w') { |f| f.puts(string_to_append) }
      end
    end
  end
end

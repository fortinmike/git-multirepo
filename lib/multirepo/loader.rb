require "pathname"

require_relative "repo"

module MultiRepo
  class Loader
    def self.load_repos(config_path)
      config = Pathname.new(config_path)
      return unless check_exists(config)
      
      repos = Array.new
      
      file = config.open("r")
      file.each_line do |line|
        components = line.split(" ")
        repos.push(MultiRepo::Repo.new(*components))
      end
      file.close
      
      return repos
    end
    
    def self.check_exists(path)
      exists = path.exist?
      puts "'#{path.basename}' file does not exist." unless exists
      return exists
    end
  end
end
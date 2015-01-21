module MultiRepo
  class Repo
    attr_accessor :folder_name
    attr_accessor :remote_url
    attr_accessor :branch_name
    
    def initialize(folder_name, remote_url, branch_name)
      @folder_name = folder_name
      @remote_url = remote_url
      @branch_name = branch_name
    end
  end
end
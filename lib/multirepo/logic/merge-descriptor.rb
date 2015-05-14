module MultiRepo
  class MergeDescriptor
    attr_accessor :name
    attr_accessor :path
    attr_accessor :revision
    attr_accessor :local_branch_name
    attr_accessor :remote_branch_name
    attr_accessor :can_ff
    
    def initialize(name, path, revision, local_branch_name, remote_branch_name, can_ff)
      @name = name
      @path = path
      @revision = revision
      @local_branch_name = local_branch_name
      @remote_branch_name = remote_branch_name
      @can_ff = can_ff
    end
  end
end
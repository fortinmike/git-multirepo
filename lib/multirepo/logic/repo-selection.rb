require "multirepo/utility/utils"

module MultiRepo
  class RepoSelection
    ALL = 0
    MAIN = 1
    DEPS = 2

    def initialize(argv)
    	@main = argv.flag?("main")
		  @deps = argv.flag?("deps")
		  @all = argv.flag?("all")
    end

    def valid?
      Utils.only_one_true?(@main, @deps, @all)
    end

    def value
    	return MAIN if @main
    	return DEPS if @deps
    	return ALL # Default if unspecified
    end
  end
end
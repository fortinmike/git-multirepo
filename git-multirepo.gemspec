# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'multirepo/version'

Gem::Specification.new do |spec|
  spec.name          = "git-multirepo"
  spec.version       = MultiRepo::VERSION
  spec.authors       = ["Michaël Fortin"]
  spec.email         = ["fortinmike@irradiated.net"]
  spec.summary       = %q{Tracks multiple side-by-side Git repositories}
  spec.description   = "MultiRepo is a work-in-progress. Use at your own risk."
  spec.homepage      = "http://www.irradiated.net"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "claide", "~> 0.8", ">= 0.8.0"
end

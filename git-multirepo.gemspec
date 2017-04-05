# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "multirepo/info"

Gem::Specification.new do |spec|
  spec.name          = MultiRepo::NAME
  spec.version       = MultiRepo::VERSION
  spec.authors       = ["Michaël Fortin"]
  spec.email         = ["fortinmike@irradiated.net"]
  spec.summary       = "Track multiple Git repositories side-by-side"
  spec.description   = MultiRepo::DESCRIPTION
  spec.homepage      = "https://github.com/fortinmike/git-multirepo"
  spec.license       = "MIT"
  
  spec.required_ruby_version = '~> 2.0'
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.1.0"

  spec.add_runtime_dependency "claide", "~> 1.0.1"
  spec.add_runtime_dependency "colored", "~> 1.2"
  spec.add_runtime_dependency "os", "~> 0.9.6"
  spec.add_runtime_dependency "terminal-table", "~> 1.7.3"
  spec.add_runtime_dependency "naturally", "~> 2.1"
end

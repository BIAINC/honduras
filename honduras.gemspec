# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'honduras/version'

Gem::Specification.new do |spec|
  spec.name          = "honduras"
  spec.version       = Honduras::VERSION
  spec.authors       = ["aliakb"]
  spec.email         = ["abaturytski@gmail.com"]
  spec.summary       = %q{Simple rufus-based resque scheduler}
  spec.description   = %q{Rufus scheduler}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "uuid"

  spec.add_runtime_dependency "redis"
  spec.add_runtime_dependency "resque"
  spec.add_runtime_dependency "rufus-scheduler"
end

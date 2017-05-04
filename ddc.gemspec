# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ddc/version'

Gem::Specification.new do |spec|
  spec.name          = "ddc"
  spec.version       = Ddc::VERSION
  spec.authors       = ["Shawn Anderson"]
  spec.email         = ["shawn42@gmail.com"]
  spec.summary       = %q{Data Driven Controllers for Rails}
  spec.description   = %q{Use data to tell Rails how to interact with your domain.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec", ">= 3.0"
  spec.add_development_dependency "pry"
  spec.add_dependency "actionpack", ">= 4.1"
  spec.add_dependency "activesupport", ">= 4.1"

end

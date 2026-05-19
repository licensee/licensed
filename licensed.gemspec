# coding: utf-8
# frozen_string_literal: true
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "licensed/version"

Gem::Specification.new do |spec|
  spec.name          = "licensed"
  spec.version       = Licensed::VERSION
  spec.authors       = ["GitHub"]
  spec.email         = ["opensource+licensed@github.com"]

  spec.summary       = %q{Extract and validate the licenses of dependencies.}
  spec.description   = "Licensed automates extracting and validating the licenses of dependencies."

  spec.homepage      = "https://github.com/github/licensed"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test/|script/|docker/|\..+)}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Keep aligned with the minimum tested Ruby version in .github/workflows/test.yml
  spec.required_ruby_version = ">= 3.3.0"

  spec.add_dependency "csv", ">= 3.3"
  spec.add_dependency "licensee", ">= 9.18"
  spec.add_dependency "thor", ">= 1.3"
  spec.add_dependency "pathname-common_prefix", ">= 0.0.2"
  spec.add_dependency "tomlrb", ">= 2.0"
  spec.add_dependency "ruby-xxHash", ">= 0.4.0"
  spec.add_dependency "parallel", ">= 1.28"
  spec.add_dependency "reverse_markdown", ">= 2.1"
  spec.add_dependency "json", ">= 2.7"
  spec.add_dependency "ostruct", ">= 0.6.3"
end

# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "dynomite/version"

Gem::Specification.new do |spec|
  spec.name          = "dynomite"
  spec.version       = Dynomite::VERSION
  spec.authors       = ["Tung Nguyen"]
  spec.email         = ["tongueroo@gmail.com"]

  spec.summary       = %q{ActiveRecord-ish Dynamodb Model}
  spec.description   = %q{ActiveRecord-ish Dynamodb Model}
  spec.homepage      = "https://github.com/tongueroo/dynomite"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "aws-sdk-dynamodb"
  spec.add_dependency "rainbow"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end

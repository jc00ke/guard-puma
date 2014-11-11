# -*- encoding: utf-8 -*-
require File.expand_path('../lib/guard/puma/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jesse Cooke"]
  gem.email         = ["jesse@jc00ke.com"]
  gem.summary       = %q{Restart puma when files change }
  gem.homepage      = "https://github.com/jc00ke/guard-puma"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "guard-puma"
  gem.require_paths = ["lib"]
  gem.version       = Guard::PumaVersion::VERSION
  gem.add_dependency              "guard", "~> 2.8"
  gem.add_dependency              "puma"
  gem.add_development_dependency  "rake", "~> 10.2"
  gem.add_development_dependency  "rspec", "~> 3.1.0"
  gem.add_development_dependency  "guard-rspec", "~> 4.3.0"
  gem.add_development_dependency  "pry"
end

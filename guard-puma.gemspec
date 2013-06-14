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
  gem.add_dependency              "guard", ">= 1.0.1"
  gem.add_dependency              "rb-inotify"
  gem.add_dependency              "libnotify"
  gem.add_dependency              "puma"
  gem.add_development_dependency  "rake", "~> 0.9.2.2"
  gem.add_development_dependency  "rspec", "~> 2.10.0"
  gem.add_development_dependency  "guard-rspec", "~> 0.7.0"
  gem.add_development_dependency  "pry"
end

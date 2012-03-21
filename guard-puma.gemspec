# -*- encoding: utf-8 -*-
require File.expand_path('../lib/guard-puma/version', __FILE__)

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
  gem.version       = Guard::Puma::VERSION
end

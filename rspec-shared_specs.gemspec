# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/shared_specs/version'

Gem::Specification.new do |spec|
  spec.name          = 'rspec-shared_specs'
  spec.version       = Rspec::SharedSpecs::VERSION
  spec.authors       = ['Michał Zajączkowski']
  spec.email         = ['michal.zajaczkowski@netguru.co']
  spec.summary       = %q{Commonly used shared specs}
  spec.description   = %q{CRUD, authentication and many others look the same in most projects. By including these specs you can avoid writing them each time.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_runtime_dependency 'rspec', '>= 3.0.0'
end

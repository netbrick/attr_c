# -*- encoding: utf-8 -*-
require File.expand_path('../lib/attr_cached/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'attr_cached'
  s.version     = AttrCached::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['jan.strnadek@gmail.com']
  s.email       = []
  s.homepage    = 'http://github.com/netbrick/attr_cached'
  s.summary     = 'Attr cache for active record models implementation'
  s.description = 'Attr cache for active record models implementation'

  s.add_dependency 'activerecord', '~> 4.0'

  s.add_development_dependency 'bundler', '>= 1.0.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'timecop'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_path = ['lib']
end

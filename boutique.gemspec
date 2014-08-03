require_relative 'lib/boutique/version'

Gem::Specification.new do |s|
  s.name        = 'boutique'
  s.version     = Boutique::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hugh Bien']
  s.email       = ['hugh@hughbien.com']
  s.homepage    = 'https://github.com/hughbien/boutique'
  s.summary     = 'Sinatra app for product checkouts and drip emails'
  s.description = 'A Sinatra app that adds product checkouts and drip emails support' +
                  ' to any websites (both UI + backend).'
 
  s.required_rubygems_version = '>= 1.3.6'
  s.add_dependency 'sinatra'
  s.add_dependency 'sequel'
  s.add_dependency 'pony'
  s.add_dependency 'tilt'
  s.add_dependency 'preamble'
  s.add_development_dependency 'shotgun'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'minitest'
 
  s.files         = Dir.glob('*.{md,rb,ru}') +
                    %w(public/boutique/script.js public/boutique/styles.css) +
                    Dir.glob('{bin,lib,migrate,test}/**/*.rb')
  s.require_paths = ['lib']
  s.bindir        = 'bin'
  s.executables   = ['boutique']
end

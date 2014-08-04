require_relative 'lib/boutique/version'

Gem::Specification.new do |s|
  s.name        = 'boutique'
  s.version     = Boutique::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hugh Bien']
  s.email       = ['hugh@hughbien.com']
  s.licenses    = ['BSD']
  s.homepage    = 'https://github.com/hughbien/boutique'
  s.summary     = 'Sinatra app for product checkouts and drip emails'
  s.description = 'A Sinatra app that adds product checkouts and drip emails support' +
                  ' to any websites (both UI + backend).'
 
  s.add_dependency 'sinatra', '~> 1.4'
  s.add_dependency 'sequel', '~> 4.12'
  s.add_dependency 'pony', '~> 1.10'
  s.add_dependency 'tilt', '~> 1.4'
  s.add_dependency 'preamble', '~> 0.0'
  s.add_development_dependency 'shotgun', '~> 0.0'
  s.add_development_dependency 'sqlite3', '~> 1.3'
  s.add_development_dependency 'rack-test', '~> 0.6'
  s.add_development_dependency 'redcarpet', '~> 3.1'
  s.add_development_dependency 'minitest', '~> 5.4'
 
  s.files         = Dir.glob('*.{md,rb,ru}') +
                    %w(public/boutique/script.js public/boutique/styles.css) +
                    Dir.glob('{bin,lib,migrate,test}/**/*.rb')
  s.require_paths = ['lib']
  s.bindir        = 'bin'
  s.executables   = ['boutique']
end

Gem::Specification.new do |s|
  s.name        = 'boutique'
  s.version     = '0.0.11'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hugh Bien']
  s.email       = ['hugh@hughbien.com']
  s.homepage    = 'https://github.com/hughbien/boutique'
  s.summary     = 'Sinatra app product checkouts and drip emails'
  s.description = 'A Sinatra app that adds product checkouts and drip emails support' +
                  ' to any websites (both UI + backend).'
 
  s.required_rubygems_version = '>= 1.3.6'
  s.add_dependency 'sinatra'
  s.add_dependency 'data_mapper'
  s.add_dependency 'pony'
  s.add_dependency 'tilt'
  s.add_dependency 'preamble'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'shotgun'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'dm-sqlite-adapter'
  s.add_development_dependency 'redcarpet'
 
  s.files         = Dir.glob('*.{md,rb,ru}') +
                    %w(boutique public/boutique/script.js public/boutique/styles.css) +
                    Dir.glob('{lib,test}/*.rb')
  s.require_paths = ['lib']
  s.bindir        = '.'
  s.executables   = ['boutique']
end

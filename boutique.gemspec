require File.expand_path('lib/boutique', File.dirname(__FILE__)) 
 
Gem::Specification.new do |s|
  s.name        = 'boutique'
  s.version     = Boutique::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Hugh Bien']
  s.email       = ['hugh@hughbien.com']
  s.homepage    = 'https://github.com/hughbien/boutique'
  s.summary     = 'Sinatra module for selling digital goods'
  s.description = 'A Sinatra module which accepts payments via PayPal and gives ' +
                  'customers a secret URL to download your product.'
 
  s.required_rubygems_version = '>= 1.3.6'
  s.add_dependency 'sinatra'
  s.add_dependency 'data_mapper'
  s.add_dependency 'pony'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'shotgun'
 
  s.files         = Dir.glob('*.{md,rb,ru}') +
                    %w(boutique) +
                    Dir.glob('{lib,test}/*.rb')
  s.require_paths = 'lib'
  s.bindir        = '.'
  s.executables   = ['boutique']
end

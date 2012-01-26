require File.expand_path('lib/boutique', File.dirname(__FILE__))

task :default => :test

task :test do
  ruby 'test/*_test.rb'
end

task :build do
  `gem build boutique.gemspec`
end

task :clean do
  rm Dir.glob('*.gem')
end

task :push => :build do
  `gem push boutique-#{Boutique::VERSION}.gem`
end

require 'rake/testtask'

task default: :test

Rake::TestTask.new do |t|
  t.pattern = 'test/*_test.rb'
end

desc 'Build boutique gem'
task :build do
  `gem build boutique.gemspec`
end

desc 'Remove build artifacts'
task :clean do
  rm Dir.glob('*.gem')
end

desc 'Push gem to rubygems.org'
task push: :build do
  require_relative 'lib/boutique/version'
  `gem push boutique-#{Boutique::VERSION}.gem`
end

desc 'Load testing data to local database'
task :fixtures do
  require_relative 'lib/boutique'
  ENV['BOUTIQUE_CMD'] = '1'
  config = File.expand_path('config.ru', File.dirname(__FILE__))
  load(config) rescue DataObjects::SyntaxError

  DataMapper.auto_migrate!
  load(config) # reload in case of product lis

  product = Boutique::Product.first(:code => 'readme')
  purchase = Boutique::Purchase.new
  product.purchases << purchase
  product.save
  purchase.complete('1337', 'john@mailinator.com', 'John')
  purchase.save

  purchase2 = Boutique::Purchase.new
  product.purchases << purchase2
  product.save
  purchase2.complete('1338', 'jane@mailinator.com', 'Jane')
  purchase2.save

  purchase2.downloads = nil
  purchase2.maybe_refresh_downloads!
end

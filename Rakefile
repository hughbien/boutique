require File.expand_path('lib/boutique', File.dirname(__FILE__))
require 'rake/testtask'
require 'dm-migrations'

task :default => :test

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
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

task :fixtures do
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

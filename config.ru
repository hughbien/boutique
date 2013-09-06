require File.expand_path('lib/boutique', File.dirname(__FILE__))

Boutique.configure(!ENV['BOUTIQUE_CMD'].nil?) do |c|
  c.email          'dev@localhost'
  c.stripe_api_key 'sk_test_abcdefghijklmnopqrstuvwxyz'
  c.download_path  '/download'
  c.download_dir   File.expand_path('temp', File.dirname(__FILE__))
  c.db_adapter     'sqlite3'
  c.db_host        'localhost'
  c.db_username    'root'
  c.db_password    'secret'
  c.db_database    'db.sqlite3'
end

Boutique.product('readme') do |p|
  p.from 'support@localhost'
  p.files File.expand_path('README.md', File.dirname(__FILE__))
  p.price 1.5
end

run Boutique::App if !ENV['BOUTIQUE_CMD']

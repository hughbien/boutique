require 'sqlite3'
require File.expand_path('lib/boutique', File.dirname(__FILE__))

Boutique.configure do |c|
  # c.error_email    'dev@localhost'
  c.stripe_api_key 'sk_test_abcdefghijklmnopqrstuvwxyz'
  c.download_path  '/download'
  c.download_dir   File.expand_path('temp', File.dirname(__FILE__))
  c.db_options(
    adapter: 'sqlite',
    host: 'localhost',
    username: 'root',
    password: 'secret',
    database: 'db.sqlite3')
  c.email_options(via: :sendmail)
end

Boutique.product('readme') do |p|
  p.from 'support@localhost'
  p.files File.expand_path('README.md', File.dirname(__FILE__))
  p.price 1.5
end

Boutique.list('learn-ruby') do |l|
  l.from   'Hugh <hugh@localhost>'
  l.emails File.expand_path('emails', File.dirname(__FILE__))
  l.url    'http://example.com'
end

run Boutique::App if !ENV['BOUTIQUE_CMD']

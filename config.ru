require File.expand_path('lib/boutique', File.dirname(__FILE__))

Boutique.configure do |c|
  c.db_adapter  'sqlite3'
  c.db_host     'localhost'
  c.db_username 'root'
  c.db_password ''
  c.db_database 'db.sqlite3'
end

run Boutique::App

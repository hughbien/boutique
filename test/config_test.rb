require File.expand_path('helper', File.dirname(__FILE__))

class ConfigTest < MiniTest::Unit::TestCase
  def test_db
    Boutique.configure do |c|
      c.db_adapter  'sqlite3'
      c.db_host     'localhost'
      c.db_username 'root'
      c.db_password 'secret'
      c.db_database 'db.sqlite3'
    end
    assert_equal('sqlite3', Boutique.config.db_adapter)
    assert_equal('localhost', Boutique.config.db_host)
    assert_equal('root', Boutique.config.db_username)
    assert_equal('secret', Boutique.config.db_password)
    assert_equal('db.sqlite3', Boutique.config.db_database)
  end
end

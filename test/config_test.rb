require File.expand_path('helper', File.dirname(__FILE__))

class ConfigTest < MiniTest::Unit::TestCase
  def test_db
    Boutique.configure do |c|
      c.db_adapter  'sqlite3'
      c.db_host     'localhost'
      c.db_username 'root'
      c.db_password 'secret'
      c.db_database 'db.sqlite3'
      c.pp_email    'paypal_biz@mailinator.com'
      c.pp_url      'https://www.sandbox.paypal.com/cgi-bin/webscr'
    end
    assert_equal('sqlite3', Boutique.config.db_adapter)
    assert_equal('localhost', Boutique.config.db_host)
    assert_equal('root', Boutique.config.db_username)
    assert_equal('secret', Boutique.config.db_password)
    assert_equal('db.sqlite3', Boutique.config.db_database)
    assert_equal('paypal_biz@mailinator.com', Boutique.config.pp_email)
    assert_equal('https://www.sandbox.paypal.com/cgi-bin/webscr', Boutique.config.pp_url)
  end
end

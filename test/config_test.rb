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

  def test_add_products
    Boutique.product('icon-set') do |p|
      p.file       File.expand_path('../README.md', File.dirname(__FILE__))
      p.price      10.5
      p.return_url 'http://zincmade.com'
    end
    assert_equal(1, Boutique.products.size)

    set = Boutique.products['icon-set']
    assert_equal(File.expand_path('../README.md', File.dirname(__FILE__)), set.file)
    assert_equal(10.5, set.price)
    assert_equal('http://zincmade.com', set.return_url)
  end
end

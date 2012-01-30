require File.expand_path('helper', File.dirname(__FILE__))

class ConfigTest < BoutiqueTest
  def test_db
    assert_equal('dev@localhost', Boutique.config.dev_email)
    assert_equal(File.expand_path('../certs/private.pem', File.dirname(__FILE__)), Boutique.config.pem_private)
    assert_equal(File.expand_path('../certs/public.pem', File.dirname(__FILE__)), Boutique.config.pem_public)
    assert_equal(File.expand_path('../certs/private.pem', File.dirname(__FILE__)), Boutique.config.pem_private)
    assert_equal('/download', Boutique.config.download_path)
    assert_equal(File.expand_path('../temp', File.dirname(__FILE__)), Boutique.config.download_dir)
    assert_equal('sqlite3', Boutique.config.db_adapter)
    assert_equal('localhost', Boutique.config.db_host)
    assert_equal('root', Boutique.config.db_username)
    assert_equal('secret', Boutique.config.db_password)
    assert_equal('db.sqlite3', Boutique.config.db_database)
    assert_equal('paypal_biz@mailinator.com', Boutique.config.pp_email)
    assert_equal('http://localhost', Boutique.config.pp_url)
  end
end

require File.expand_path('helper', File.dirname(__FILE__))

class ConfigTest < BoutiqueTest
  def test_db
    assert_equal('dev@localhost', Boutique.config.dev_email)
    assert_equal(
      'sk_test_abcdefghijklmnopqrstuvwxyz',
      Boutique.config.stripe_api_key)
    assert_equal('/download', Boutique.config.download_path)
    assert_equal(
      File.expand_path('../temp', File.dirname(__FILE__)),
      Boutique.config.download_dir)
    assert_equal({
      adapter: 'sqlite3',
      host: 'localhost',
      username: 'root',
      password: 'secret',
      database: 'db.sqlite3'},
      Boutique.config.db_options)
    assert_equal({via: :sendmail}, Boutique.config.email_options)
  end
end

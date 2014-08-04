require_relative 'helper'

class ConfigTest < BoutiqueTest
  def test_db
    assert_equal('dev@localhost', Boutique.config.error_email)
    assert_equal(
      'sk_test_abcdefghijklmnopqrstuvwxyz',
      Boutique.config.stripe_api_key)
    assert_equal('/download', Boutique.config.download_path)
    assert_equal(
      File.expand_path('../temp', File.dirname(__FILE__)),
      Boutique.config.download_dir)
    assert_equal('sqlite::memory:', Boutique.config.db_options)
    assert_equal({via: :sendmail}, Boutique.config.email_options)
  end
end

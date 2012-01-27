require File.expand_path('helper', File.dirname(__FILE__))

class BoutiqueTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def setup
    Boutique::Product.all.destroy
    Boutique::Config.pp_url('http://localhost')
    Boutique::Config.pp_email('paypal_biz@mailinator.com')
  end

  def test_redirect_to_paypal
    ebook_product.save
    get '/ebook'
    assert(last_response.redirect?)
    assert(
      ebook_product.paypal_url('http://localhost/notify'),
      last_response.headers['Location'])
  end

  def test_purchase_non_existing_product
    get '/non-existing-product'
    assert(last_response.not_found?)
  end

  private
  def app
    @app ||= Rack::Server.new.app
  end

  def ebook_product
    Boutique::Product.new(
      :code => 'ebook',
      :name => 'Ebook',
      :file => File.expand_path('../README.md', File.dirname(__FILE__)),
      :price => 10.5,
      :return_url => 'http://zincmade.com')
  end
end

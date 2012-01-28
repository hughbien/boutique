require File.expand_path('helper', File.dirname(__FILE__))

class BoutiqueTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def setup
    Boutique::Product.all.destroy
    Boutique::Purchase.all.destroy
    Boutique::Config.pp_url('http://localhost')
    Boutique::Config.pp_email('paypal_biz@mailinator.com')
    Boutique::Config.download_dir(File.expand_path('../temp', File.dirname(__FILE__)))
  end

  def test_redirect_to_paypal
    ebook_product.save
    get '/buy/ebook'

    purchase = Boutique::Purchase.first
    refute(purchase.nil?)

    assert(last_response.redirect?)
    assert(
      purchase.paypal_url('http://localhost/notify'),
      last_response.headers['Location'])
  end

  def test_purchase_non_existing_product
    get '/buy/non-existing-product'
    assert(last_response.not_found?)
  end

  def test_notify
    product = ebook_product
    purchase = Boutique::Purchase.new
    product.purchases << purchase
    product.save
    refute(purchase.completed?)

    get "/notify/#{purchase.boutique_id}?payment_status=Completed&txn_id=1337&receiver_email=#{Boutique.config.pp_email}"
    assert(last_response.ok?)

    purchase.reload
    assert(purchase.completed?)
    assert_equal('1337', purchase.transaction_id)
  end

  def test_notify_not_found
    get "/notify/99-notfound"
    assert(last_response.not_found?)
  end

  def test_record
    product = ebook_product
    purchase = Boutique::Purchase.new
    product.purchases << purchase
    product.save

    get "/record/#{purchase.boutique_id}"
    assert(last_response.ok?)

    json = JSON.parse(last_response.body)
    assert(json['id'])
    assert_equal('ebook', json['code'])
    assert_equal('Ebook', json['name'])
    assert_equal(0, json['counter'])
    refute(json['completed'])
  end

  def test_record_not_found
    get "/record/99-notfound"
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
      :files => [File.expand_path('../README.md', File.dirname(__FILE__))],
      :price => 10.5,
      :return_url => 'http://zincmade.com')
  end
end

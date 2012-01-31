require File.expand_path('helper', File.dirname(__FILE__))

class AppTest < BoutiqueTest
  include Rack::Test::Methods

  def test_redirect_to_paypal
    ebook_product.save
    post '/buy/ebook'

    purchase = Boutique::Purchase.first
    refute(purchase.nil?)
    assert(last_response.ok?)
  end

  def test_purchase_non_existing_product
    post '/buy/non-existing-product'
    assert(last_response.not_found?)
  end

  def test_notify
    product = ebook_product
    purchase = Boutique::Purchase.new
    product.purchases << purchase
    product.save
    refute(purchase.completed?)
    assert_nil(Pony.last_mail)

    post "/notify/#{purchase.boutique_id}?payment_status=Completed&txn_id=1337&receiver_email=#{Boutique.config.pp_email}&payer_email=john@mailinator.com&first_name=John"
    assert(last_response.ok?)

    purchase.reload
    assert(purchase.completed?)
    refute_nil(Pony.last_mail)
    assert_equal('1337', purchase.transaction_id)
  end

  def test_notify_not_found
    post "/notify/99-notfound"
    assert(last_response.not_found?)
  end

  def test_recover
    purchase = ebook_purchase
    purchase.complete('1337', 'john@mailinator.com', 'John')
    purchase.save
    assert_nil(Pony.last_mail)

    post "/recover/ebook", 'email' => 'john@mailinator.com'
    assert(last_response.ok?)
    assert_equal(purchase.boutique_id, last_response.body)
    refute_nil(Pony.last_mail)
  end

  def test_recover_not_found
    post "/recover/99-notfound"
    assert(last_response.not_found?)
  end

  def test_record
    purchase = ebook_purchase
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
  def ebook_purchase
    product = ebook_product
    purchase = Boutique::Purchase.new
    product.purchases << purchase
    product.save
    purchase
  end

  def app
    @app ||= Rack::Server.new.app
  end
end

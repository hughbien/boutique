require File.expand_path('helper', File.dirname(__FILE__))

class ModelTest < MiniTest::Unit::TestCase
  def setup
    Boutique::Purchase.all.destroy
    Boutique::Product.all.destroy
    Boutique::Config.pp_url('http://localhost')
    Boutique::Config.pp_email('paypal_biz@mailinator.com')
    Boutique::Config.download_dir(File.expand_path('../temp', File.dirname(__FILE__)))
  end

  def test_purchase_create
    product = ebook_product
    product.save
    count = Boutique::Purchase.count
    purchase = Boutique::Purchase.create({})
    product.purchases << purchase
    product.save

    assert_equal(count + 1, Boutique::Purchase.count)
    assert_equal(0, purchase.counter)
    assert_nil(purchase.transaction_id)
    assert_nil(purchase.completed_at)
    assert_nil(purchase.downloads)
    refute_nil(purchase.secret)
    refute(purchase.completed?)

    purchase.complete('1')
    purchase.save
    assert_equal('1', purchase.transaction_id)
    refute_nil(purchase.completed_at)
    assert(purchase.completed?)
    assert_match(%r(/download/[^/]+/README.md), purchase.downloads[0])

    bid = purchase.boutique_id
    assert_equal(purchase.id, bid.split('-')[0].to_i)
    assert_equal(10, bid.split('-')[1].size)

    assert_match(
      'http://localhost?business=paypal_biz%40mailinator.com&cmd=_xclick&item_name=Ebook&item_number=ebook&amount=0.105E2&currency_code=USD&notify_url=http%3A%2F%2Flocalhost%2Fnotify',
      purchase.paypal_url('http://localhost/notify')
    )

    json = JSON.parse(purchase.to_json)
    assert_equal(purchase.id, json['id'])
    assert_equal(1, json['counter'])
    assert(json['completed'])
    assert_equal('Ebook', json['name'])
    assert_equal('ebook', json['code'])
    refute_nil(json['downloads'])
  end

  def test_product_create
    count = Boutique::Product.count
    Boutique.product('icon-set') do |p|
      p.name       'Icon Set'
      p.files      [File.expand_path('../README.md', File.dirname(__FILE__))]
      p.price      10.5
      p.return_url 'http://zincmade.com'
    end
    assert_equal(count + 1, Boutique::Product.count)

    set = Boutique::Product.first(:code => 'icon-set')
    assert_equal('Icon Set', set.name)
    assert_equal(File.expand_path('../README.md', File.dirname(__FILE__)), set.files[0])
    assert_equal(10.5, set.price)
    assert_equal('http://zincmade.com', set.return_url)
    assert_equal(0, set.purchases.size)
  end

  private
  def ebook_product
    Boutique::Product.new(
      :code => 'ebook',
      :name => 'Ebook',
      :files => [File.expand_path('../README.md', File.dirname(__FILE__))],
      :price => 10.5,
      :return_url => 'http://zincmade.com')
  end
end

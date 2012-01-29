require File.expand_path('helper', File.dirname(__FILE__))

class ModelTest < BoutiqueTest
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
    refute_nil(purchase.created_at)
    refute(purchase.completed?)

    purchase.complete('1', 'john@mailinator.com', 'John')
    purchase.save
    assert_equal('1', purchase.transaction_id)
    refute_nil(purchase.completed_at)
    assert(purchase.completed?)
    assert_match(%r(/download/[^/]+/README.md), purchase.downloads[0])

    old_download = purchase.downloads[0]
    `rm #{Boutique.config.download_dir}#{old_download.sub(Boutique.config.download_path, '')}`
    purchase.maybe_refresh_downloads!
    refute_equal(old_download, purchase.downloads[0])

    bid = purchase.boutique_id
    assert_equal(purchase.id, bid.split('-')[0].to_i)
    assert_equal(10, bid.split('-')[1].size)

    form = purchase.paypal_form('http://localhost/notify')
    assert_equal('http://localhost', form['action'])
    assert_equal('_s-xclick', form['cmd'])
    refute_nil(form['encrypted'])

    json = JSON.parse(purchase.to_json)
    assert_equal(purchase.id, json['id'])
    assert_equal(2, json['counter'])
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
end

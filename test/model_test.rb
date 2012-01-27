require File.expand_path('helper', File.dirname(__FILE__))

class PurchaseTest < MiniTest::Unit::TestCase
  def setup
    Boutique::Purchase.all.destroy
    Boutique::Product.all.destroy
  end

  def test_purchase_create
    product = Boutique::Product.create(
      :code => 'ebook',
      :name => 'Ebook',
      :file => File.expand_path('../README.md', File.dirname(__FILE__)),
      :price => 10.5,
      :return_url => 'http://zincmade.com')
    count = Boutique::Purchase.count
    purchase = Boutique::Purchase.create({})
    product.purchases << purchase
    product.save
    assert_equal(count + 1, Boutique::Purchase.count)
    assert_equal(0, purchase.counter)
  end

  def test_product_create
    count = Boutique::Product.count
    Boutique.product('icon-set') do |p|
      p.name       'Icon Set'
      p.file       File.expand_path('../README.md', File.dirname(__FILE__))
      p.price      10.5
      p.return_url 'http://zincmade.com'
    end
    assert_equal(count + 1, Boutique::Product.count)

    set = Boutique::Product.first(:code => 'icon-set')
    assert_equal('Icon Set', set.name)
    assert_equal(File.expand_path('../README.md', File.dirname(__FILE__)), set.file)
    assert_equal(10.5, set.price)
    assert_equal('http://zincmade.com', set.return_url)
    assert_equal(0, set.purchases.size)
  end
end

require File.expand_path('helper', File.dirname(__FILE__))

class PurchaseTest < MiniTest::Unit::TestCase
  def test_purchase_create
    count = Boutique::Purchase.count
    purchase = Boutique::Purchase.create(
      :product => 'icon-set',
      :file => File.expand_path('../README.md', File.dirname(__FILE__)),
      :price => 100.05,
      :return_url => 'http://zincmade.com')
    assert_equal(0, purchase.counter)
    assert_equal(count + 1, Boutique::Purchase.count)
  end

  def test_product_create
    count = Boutique::Product.count
    Boutique.product('icon-set') do |p|
      p.file       File.expand_path('../README.md', File.dirname(__FILE__))
      p.price      10.5
      p.return_url 'http://zincmade.com'
    end
    assert_equal(count + 1, Boutique::Product.count)

    set = Boutique::Product.first('icon-set')
    assert_equal(File.expand_path('../README.md', File.dirname(__FILE__)), set.file)
    assert_equal(10.5, set.price)
    assert_equal('http://zincmade.com', set.return_url)
  end
end

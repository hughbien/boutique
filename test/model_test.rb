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
end

require File.expand_path('helper', File.dirname(__FILE__))

class ModelTest < MiniTest::Unit::TestCase
  def test_purchase
    purchase = Boutique::Purchase.create({})
    assert(purchase)
  end
end

require File.expand_path('helper', File.dirname(__FILE__))

class ModelTest < BoutiqueTest
  def test_product_create
    count = Boutique::Product.count
    Boutique.product('icon-set') do |p|
      p.from  'support@zincmade.com'
      p.files [File.expand_path('../README.md', File.dirname(__FILE__))]
      p.price 10.5
    end
    assert_equal(count + 1, Boutique::Product.count)

    set = Boutique::Product.first(code: 'icon-set')
    assert_equal(
      File.expand_path('../README.md', File.dirname(__FILE__)),
      set.files[0])
    assert_equal(10.5, set.price)
    assert_equal('support@zincmade.com', set.from)
    assert_equal(0, set.purchases.size)
  end
end

require File.expand_path('helper', File.dirname(__FILE__))

class ModelTest < BoutiqueTest
  def test_product
    Boutique.product('icon-set') do |p|
      p.from  'support@zincmade.com'
      p.files [File.expand_path('../README.md', File.dirname(__FILE__))]
      p.price 10.5
    end

    set = Boutique::Product['icon-set']
    assert_equal('icon-set', set.key)
    assert_equal(
      File.expand_path('../README.md', File.dirname(__FILE__)),
      set.files[0])
    assert_equal(10.5, set.price)
    assert_equal('support@zincmade.com', set.from)
  end

  def test_list
    list = new_list
    assert_equal('learn-icon', list.key)
    assert_equal('learn-icon@example.com', list.from)
    assert_equal('/path/to/emails-dir', list.emails)
  end

  def test_subscriber
    list = new_list
    subscriber = Boutique::Subscriber.new(
      list_key: 'learn-icon',
      email: 'john@mailinator.com')
    subscriber.save
    refute(subscriber.confirmed?)
    assert_equal(1, list.subscribers.count)
    assert_equal(subscriber, list.subscribers.first)
  end

  def test_subscriber_email_validation
    list =  new_list
    subscriber = Boutique::Subscriber.new(
      list_key: 'learn-icon',
      email: 'invalid-email')
    refute(subscriber.valid?)
    refute_empty(subscriber.errors[:email])
  end

  def test_subscriber_list_key_validation
    subscriber = Boutique::Subscriber.new(
      list_key: 'invalid-list-key',
      email: 'john@mailinator.com')
    refute(subscriber.valid?)
    refute_empty(subscriber.errors[:list_key])
  end

  def test_subscriber_list_email_unique
    list = new_list
    attrs = {list_key: list.key, email: 'john@mailinator.com'}
    Boutique::Subscriber.create(attrs)
    subscriber = Boutique::Subscriber.new(attrs)
    refute(subscriber.valid?)
    refute_empty(subscriber.errors[:email])
  end
end

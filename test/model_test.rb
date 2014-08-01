require_relative 'helper'

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
    assert_equal('http://example.com', list.url)
    assert_equal(File.expand_path('../emails', File.dirname(__FILE__)), list.emails)
    assert_equal("http://example.com?boutique=subscribe/learn-icon", list.subscribe_url)
  end

  def test_subscriber
    list = new_list
    subscriber = Boutique::Subscriber.new(
      list_key: 'learn-icon',
      email: 'john@mailinator.com')
    subscriber.save
    refute(subscriber.confirmed)
    refute_nil(subscriber.secret)
    assert_equal(1, list.subscribers.count)
    assert_equal(subscriber, list.subscribers.first)
    assert_equal(0, subscriber.drip_day)
    assert_equal(Date.today, subscriber.drip_on)

    id, secret = subscriber.id, subscriber.secret
    assert_equal(
      "http://example.com?boutique=confirm/learn-icon/#{id}/#{secret}",
      subscriber.confirm_url)
    assert_equal(
      "http://example.com?boutique=unsubscribe/learn-icon/#{id}/#{secret}",
      subscriber.unsubscribe_url)
  end

  def test_subscriber_email_validation
    list = new_list
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

  def test_email_unique
    list = new_list
    sub = Boutique::Subscriber.create(list_key: list.key, email: 'john@mailinator.com')
    Boutique::Email.create(email_key: 'first', subscriber: sub)
    email = Boutique::Email.new(email_key: 'first', subscriber: sub)
    refute(email.valid?)
    refute_empty(email.errors[:email_key])
    sub2 = Boutique::Subscriber.create(list_key: list.key, email: 'jane@mailinator.com')
    email = Boutique::Email.create(email_key: 'first', subscriber: sub2)
    assert(email.valid?)
  end
end

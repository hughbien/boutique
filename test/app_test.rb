require File.expand_path('helper', File.dirname(__FILE__))

class AppTest < BoutiqueTest
  include Rack::Test::Methods

  def test_subscribe
    list = new_list
    get "/subscribe/#{list.key}", email: 'john@mailinator.com', jsonp: 'callback'
    assert(last_response.ok?)
    assert_equal('"callback()"', last_response.body.inspect)
    assert_equal(1, Boutique::Subscriber.count)
    assert_equal(1, Boutique::Email.count)
    refute_nil(Pony.last_mail)
    subscriber = Boutique::Subscriber.first
    refute(subscriber.confirmed)
  end

  def test_subscribe_invalid
    list = new_list
    get "/subscribe/#{list.key}", email: 'invalid-email'
    assert_equal(400, last_response.status)
  end

  def test_confirm
    list = new_list
    subscriber = Boutique::Subscriber.create(list_key: list.key, email: 'john@mailinator.com')
    refute(subscriber.confirmed)
    get "/confirm/#{list.key}/#{subscriber.id}/#{subscriber.secret}"
    assert(last_response.ok?)
    subscriber = Boutique::Subscriber[subscriber.id]
    assert(subscriber.confirmed)
  end

  def test_unsubscribe
    list = new_list
    subscriber = Boutique::Subscriber.new(list_key: list.key, email: 'john@mailinator.com')
    subscriber.confirmed = true
    subscriber.save
    assert(subscriber.confirmed)
    get "/unsubscribe/#{list.key}/#{subscriber.id}/#{subscriber.secret}"
    assert(last_response.ok?)
    subscriber = Boutique::Subscriber[subscriber.id]
    refute(subscriber.confirmed)
  end

  private
  def app
    @app ||= Rack::Server.new.app
  end
end

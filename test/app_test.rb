require File.expand_path('helper', File.dirname(__FILE__))

class AppTest < BoutiqueTest
  include Rack::Test::Methods

  def test_subscribe
    list = new_list
    post "/subscribe/#{list.key}", email: 'john@mailinator.com'
    assert(last_response.ok?)
    assert_equal(1, Boutique::Subscriber.count)
    subscriber = Boutique::Subscriber.first
    refute(subscriber.confirmed?)
  end

  def test_confirm
    list = new_list
    subscriber = Boutique::Subscriber.create(
      list_key: list.key, email: 'john@mailinator.com')
    refute(subscriber.confirmed?)
    post "/confirm/#{list.key}/#{subscriber.id}/#{subscriber.secret}"
    assert(last_response.ok?)
    subscriber = Boutique::Subscriber.get(subscriber.id)
    assert(subscriber.confirmed?)
  end

  def test_unsubscribe
    list = new_list
    subscriber = Boutique::Subscriber.create(
      list_key: list.key, email: 'john@mailinator.com', confirmed: true)
    assert(subscriber.confirmed?)
    post "/unsubscribe/#{list.key}/#{subscriber.id}/#{subscriber.secret}"
    assert(last_response.ok?)
    subscriber = Boutique::Subscriber.get(subscriber.id)
    refute(subscriber.confirmed?)
  end

  private
  def app
    @app ||= Rack::Server.new.app
  end
end

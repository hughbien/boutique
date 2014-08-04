require_relative 'helper'

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

  def test_subscribe_error
    list = new_list
    find_or_create = lambda { |*args| raise('Stubbed Error') }
    Boutique::Subscriber.stub(:find_or_create, find_or_create) do
      assert_raises(RuntimeError) do
        get "/subscribe/#{list.key}", email: 'john@mailinator.com'
      end
    end
    mail = Pony.last_mail
    assert_equal('dev@localhost', mail[:to])
    assert_equal('[Boutique Error] Stubbed Error', mail[:subject])
    assert(mail[:body])
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

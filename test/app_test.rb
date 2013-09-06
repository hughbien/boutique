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

  private
  def app
    @app ||= Rack::Server.new.app
  end
end

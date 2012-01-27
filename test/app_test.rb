require File.expand_path('helper', File.dirname(__FILE__))

class BoutiqueTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def test_ok
    get '/'
    assert last_response.ok?
    assert_equal 'test', last_response.body
  end

  private
  def app
    @app ||= Rack::Server.new.app
  end
end

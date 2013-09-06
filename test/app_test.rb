require File.expand_path('helper', File.dirname(__FILE__))

class AppTest < BoutiqueTest
  include Rack::Test::Methods

  private
  def app
    @app ||= Rack::Server.new.app
  end
end

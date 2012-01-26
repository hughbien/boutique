require 'rubygems'
require 'sinatra/base'

module Boutique
  VERSION = '0.0.1'

  class App < Sinatra::Base
    get '/' do
      'test'
    end
  end
end

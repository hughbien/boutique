require 'rubygems'
require 'sinatra/base'
require 'dm-core'

module Boutique
  VERSION = '0.0.1'

  class << self
    def configure
      yield Config
    end

    def config
      Config
    end

    def init
      DataMapper.setup(:default,
        :adapter  => config.db_adapter,
        :host     => config.db_host,
        :username => config.db_username,
        :password => config.db_password,
        :database => config.db_database
      )
    end
  end

  class Config
    def self.db_adapter(value=nil)
      @db_adapter = value if !value.nil?
      @db_adapter
    end

    def self.db_host(value=nil)
      @db_host = value if !value.nil?
      @db_host
    end

    def self.db_username(value=nil)
      @db_username = value if !value.nil?
      @db_username
    end

    def self.db_password(value=nil)
      @db_password = value if !value.nil?
      @db_password
    end

    def self.db_database(value=nil)
      @db_database = value if !value.nil?
      @db_database
    end
  end

  class Purchase
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :product, String
    property :file, String
    property :price, Decimal
    property :return_url, String
    property :counter, Integer

    def initialize(attr = {})
      attr[:counter] ||= 0
      super
    end
  end

  class App < Sinatra::Base
    get '/' do
      'test'
    end
  end
end

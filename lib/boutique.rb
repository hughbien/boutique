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

    def product(id)
      builder = ProductBuilder.new
      yield builder
      products[id] = Product.new(
        id, builder.file, builder.price, builder.return_url)
    end

    def products
      @products ||= {}
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

  class ProductBuilder
    def file(value=nil)
      @file = value if !value.nil?
      @file
    end

    def price(value=nil)
      @price = value if !value.nil?
      @price
    end

    def return_url(value=nil)
      @return_url = value if !value.nil?
      @return_url
    end
  end

  class Product
    attr_reader :id, :file, :price, :return_url

    def initialize(id, file, price, return_url)
      @id = id
      @file = file
      @price = price
      @return_url = return_url
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

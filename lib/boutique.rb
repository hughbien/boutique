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

    def product(name)
      builder = ProductBuilder.new
      builder.name(name)
      yield builder
      product = Product.first_or_create({:name => name}, builder.to_hash)
      product.save
      product
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

    def self.pp_email(value=nil)
      @pp_email = value if !value.nil?
      @pp_email
    end

    def self.pp_url(value=nil)
      @pp_url = value if !value.nil?
      @pp_url
    end
  end

  class ProductBuilder
    def name(value=nil)
      @name = value if !value.nil?
      @name
    end

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

    def to_hash
      {:name => @name,
       :file => @file,
       :price => @price,
       :return_url => return_url}
    end
  end

  class Product
    include DataMapper::Resource

    property :id, Serial
    property :name, String, :required => true, :unique => true
    property :file, String, :required => true
    property :price, Decimal, :required => true
    property :return_url, String, :required => true

    has n, :purchases

    def paypal_url
      values = {
        :business => Boutique.config.pp_email,
        :cmd => '_xclick',
        :item_name => name,
        :item_number => 'product-identifier',
        :amount => price,
        :currency_code => 'USD'
      }
    end
  end

  class Purchase
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :counter, Integer, :required => true

    belongs_to :product

    def initialize(attr = {})
      attr[:counter] ||= 0
      super
    end
  end

  DataMapper.finalize

  class App < Sinatra::Base
    get '/' do
      'test'
    end
  end
end

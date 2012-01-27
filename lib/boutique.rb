require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'cgi'
require 'date'
require 'digest/sha1'

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

    def product(code)
      builder = ProductBuilder.new
      builder.code(code)
      yield builder
      product = Product.first_or_create({:code => code}, builder.to_hash)
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
    def code(value=nil)
      @code = value if !value.nil?
      @code
    end

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
      {:code => @code,
       :name => @name,
       :file => @file,
       :price => @price,
       :return_url => @return_url}
    end
  end

  class Product
    include DataMapper::Resource

    property :id, Serial
    property :code, String, :required => true, :unique => true
    property :name, String, :required => true, :unique => true
    property :file, String, :required => true
    property :price, Decimal, :required => true
    property :return_url, String, :required => true

    has n, :purchases
  end

  class Purchase
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :counter, Integer, :required => true
    property :secret, String, :required => true
    property :transaction_id, String
    property :completed_at, DateTime

    belongs_to :product

    def initialize(attr = {})
      attr[:counter] ||= 0
      attr[:secret] ||= Digest::SHA1.hexdigest("#{DateTime.now}#{rand}")[0..9]
      super
    end

    def complete(txn_id)
      self.transaction_id = txn_id
      self.completed_at = DateTime.now
    end

    def completed?
      !completed_at.nil? && !transaction_id.nil?
    end

    def boutique_id
      (self.id.nil? || self.secret.nil?) ?
        raise('Cannot get boutique_id for unsaved purchase') :
        "#{self.id}-#{self.secret}"
    end

    def paypal_url(notify_url)
      values = {
        :business => Boutique.config.pp_email,
        :cmd => '_xclick',
        :item_name => product.name,
        :item_number => product.code,
        :amount => product.price,
        :currency_code => 'USD',
        :notify_url => "#{notify_url}/b=#{boutique_id}",
        :return => "#{product.return_url}?b=#{boutique_id}"
      }
      query = values.map { |kv| "#{CGI.escape(kv[0].to_s)}=#{CGI.escape(kv[1].to_s)}" }.join('&')
      "#{Boutique.config.pp_url}?#{query}"
    end
  end

  DataMapper.finalize

  class App < Sinatra::Base
    get '/buy/:code' do
      product = Boutique::Product.first(:code => params[:code])
      if product.nil?
        halt(404, "product #{params[:code]} not found")
      end
      purchase = Boutique::Purchase.new
      product.purchases << purchase
      product.save
      redirect(purchase.paypal_url("http://#{request.host}/notify"))
    end

    get '/notify/:boutique_id' do
      id, secret = params[:boutique_id].split('-')
      purchase = Boutique::Purchase.get(id)
      if purchase.nil? || purchase.secret != secret
        halt(404, "purchase #{params[:boutique_id]} not found")
      end
      if params['txn_id'] && params['payment_status']
        purchase.complete(params[:txn_id])
        purchase.save
      end
      ''
    end
  end
end

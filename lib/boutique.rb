require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'date'
require 'digest/sha1'
require 'json'
require 'openssl'
require 'pony'

DataMapper::Model.raise_on_save_failure = true

module Boutique
  VERSION = '0.0.9'

  class << self
    def configure(setup_db=true)
      yield Config
      DataMapper.setup(:default,
        :adapter  => config.db_adapter,
        :host     => config.db_host,
        :username => config.db_username,
        :password => config.db_password,
        :database => config.db_database
      ) if setup_db
    end

    def config
      Config
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

  module AttrOption
    def attr_option(*names)
      options = names.last.is_a?(Hash) ? names.pop : {}
      klass = options[:singleton] ? singleton_class : self
      names.each do |name|
        klass.send(:define_method, name) do |*args|
          value = args[0]
          instance_variable_set("@#{name}".to_sym, value) if !value.nil?
          instance_variable_get("@#{name}".to_sym)
        end
      end
      klass.send(:define_method, :to_hash) do
        hash = {}
        names.each do
          |name| hash[name.to_sym] = instance_variable_get("@#{name}".to_sym)
        end
        hash
      end
    end

    def cattr_option(*names)
      attr_option(*names, singleton: true)
    end
  end

  class Config
    extend AttrOption
    cattr_option :email,
      :stripe_api_key,
      :download_dir,
      :download_path,
      :db_adapter,
      :db_host,
      :db_username,
      :db_password,
      :db_database
  end

  class ProductBuilder
    extend AttrOption
    attr_option :code, :from, :files, :price
  end

  class Product
    include DataMapper::Resource

    property :id, Serial
    property :code, String, required: true, unique: true
    property :files, CommaSeparatedList, required: true
    property :price, Decimal, required: true
    property :from, String, required: true

    has n, :purchases
  end

  class Purchase
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :counter, Integer, required: true
    property :secret, String, required: true
    property :transaction_id, String
    property :email, String
    property :name, String
    property :completed_at, DateTime
    property :downloads, CommaSeparatedList

    belongs_to :product
  end

  DataMapper.finalize

  class App < Sinatra::Base
    set :raise_errors, false
    set :show_exceptions, false

    error do
      Pony.mail(
        :to => Boutique.config.email,
        :from => "boutique@#{Boutique.config.email.split('@')[1..-1].join}",
        :subject => 'Boutique Error',
        :body => request.env['sinatra.error'].to_s
      ) if Boutique.config.email
    end
  end
end

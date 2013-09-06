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
      yield config
      DataMapper.setup(:default,
        :adapter  => config.db_adapter,
        :host     => config.db_host,
        :username => config.db_username,
        :password => config.db_password,
        :database => config.db_database
      ) if setup_db
    end

    def config
      @config ||= Config.new('config')
    end

    def product(key)
      yield Product.new(key)
    end

    def list(key)
      yield List.new(key)
    end
  end

  module MemoryResource
    def self.included(base)
      base.extend(ClassMethods)
      base.attr_resource :key
      base.reset_db
    end

    module ClassMethods
      def attr_resource(*names)
        names.each do |name|
          define_method(name) do |*args|
            value = args[0]
            instance_variable_set("@#{name}".to_sym, value) if !value.nil?
            instance_variable_get("@#{name}".to_sym)
          end
        end
      end

      def reset_db
        @db = {}
      end

      def [](key)
        @db[key]
      end

      def []=(key, value)
        @db[key] = value
      end
    end

    def initialize(key)
      @key = key
      self.class[key] = self
    end
  end

  class Config
    include MemoryResource
    attr_resource :email,
      :stripe_api_key,
      :download_dir,
      :download_path,
      :db_adapter,
      :db_host,
      :db_username,
      :db_password,
      :db_database
  end

  class Product
    include MemoryResource
    attr_resource :from, :files, :price
  end

  class List
    include MemoryResource
    attr_resource :from, :emails

    def subscribers
      Subscriber.all(list_key: self.key)
    end
  end

  class Purchase
    include DataMapper::Resource

    property :id, Serial
    property :product_key, String, required: true
    property :created_at, DateTime
    property :counter, Integer, required: true
    property :secret, String, required: true
    property :transaction_id, String
    property :email, String
    property :name, String
    property :completed_at, DateTime
    property :downloads, CommaSeparatedList
  end

  class Subscriber
    include DataMapper::Resource

    property :id, Serial
    property :list_key, String, required: true
    property :created_at, DateTime
    property :confirmed, Boolean
    property :email, String
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

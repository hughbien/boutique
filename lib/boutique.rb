require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-types'
require 'dm-timestamps'
require 'dm-validations'
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

      def include?(key)
        self.to_a.include?(key)
      end

      def to_a
        @db.keys
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
    property :name, String, format: :email_address
    property :completed_at, DateTime
    property :downloads, CommaSeparatedList
  end

  class Subscriber
    include DataMapper::Resource

    property :id, Serial
    property :list_key, String, required: true, unique_index: :list_key_email
    property :email, String, required: true, unique_index: :list_key_email, format: :email_address
    property :secret, String, required: true
    property :created_at, DateTime
    property :confirmed, Boolean

    validates_within :list_key, set: List
    validates_uniqueness_of :email, scope: :list_key

    before :valid?, :generate_secret

    def generate_secret
      self.secret ||= Digest::SHA1.hexdigest("#{rand(1000)}-#{Time.now}")[0..6]
    end

    def confirm!(secret)
      self.confirmed = true if self.secret == secret
      self.save
    end

    def unconfirm!(secret)
      self.confirmed = false if self.secret == secret
      self.save
    end
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

    post '/subscribe/:list_key' do
      Subscriber.create(
        list_key: params[:list_key],
        email: params[:email])
      ''
    end

    get '/subscribe/:list_key/:id/:secret' do
      subscriber = Subscriber.first(id: params[:id], list_key: params[:list_key])
      subscriber.confirm!(params[:secret])
      ''
    end

    get '/unsubscribe/:list_key/:id/:secret' do
      subscriber = Subscriber.first(id: params[:id], list_key: params[:list_key])
      subscriber.unconfirm!(params[:secret])
      ''
    end
  end
end

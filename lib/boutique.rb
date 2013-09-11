require 'rubygems'
require 'bundler/setup'
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
require 'preamble'
require 'tilt'
require 'tempfile'
require 'uri'
require 'cgi'

DataMapper::Model.raise_on_save_failure = true

module Boutique
  VERSION = '0.0.10'

  class << self
    def configure(setup_db=true)
      yield config
      DataMapper.setup(:default, config.db_options) if setup_db
      Pony.options = config.email_options if !config.email_options.nil?
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

  class Emailer
    def initialize(list, directory = nil)
      @list = list
      @directory = directory
    end

    def render(path, locals = {}, preamble = false)
      path = @directory ?
        File.join(@directory, path) :
        full_path(path)
      raise "File not found: #{path}" if !File.exist?(path)

      yaml, body = preamble(path)
      templates_for(path).each do |template|
        blk = proc { body }
        body = template.new(path, &blk).render(self, locals)
      end

      preamble ? [yaml, body] : body
    end

    def deliver(subscriber, path, locals = {})
      locals = locals.merge(
        subscribe_url: @list.subscribe_url,
        confirm_url: subscriber.confirm_url,
        unsubscribe_url: subscriber.unsubscribe_url)
      yaml, body = self.render(path, locals, true)
      if yaml['day'] == 0
        ymd = Date.today.strftime("%Y-%m-%d")
        Email.create(email_key: "#{yaml['key']}-#{ymd}", subscriber: subscriber)
      else
        raise "Unconfirmed #{subscriber.email} for #{yaml['key']}" if !subscriber.confirmed?
        Email.create(email_key: yaml['key'], subscriber: subscriber)
      end
      Pony.mail(
        to: subscriber.email,
        from: @list.from,
        subject: yaml['subject'],
        headers: {'Content-Type' => 'text/html'},
        body: body)
    rescue DataMapper::SaveFailureError
      raise "Duplicate email #{yaml['key']} to #{subscriber.email}"
    end

    def deliver_zero(subscriber)
      self.deliver(subscriber, emails[0])
    end

    def blast(path, locals = {})
      yaml, body = preamble(full_path(path))
      email_key = yaml['key']
      @list.subscribers.all(confirmed: true).each do |subscriber|
        # TODO: speed up by moving filter outside of loop
        if Email.first(email_key: yaml['key'], subscriber: subscriber).nil?
          self.deliver(subscriber, path, locals)
        end
      end
    end

    def drip
      today = Date.today
      max_day = emails.keys.max || 0
      subscribers = @list.subscribers.all(
        :confirmed => true,
        :drip_on.lt => today,
        :drip_day.lt => max_day)
      subscribers.each do |subscriber|
        subscriber.drip_on = today
        subscriber.drip_day += 1
        subscriber.save
        if (email_path = emails[subscriber.drip_day])
          self.deliver(subscriber, email_path)
        end
      end
    end

    private
    def full_path(path)
      File.join(@list.emails, path)
    end

    def templates_for(path)
      basename = File.basename(path)
      basename.split('.')[1..-1].reverse.map { |ext| Tilt[ext] }
    end

    def emails
      @emails ||= begin
        emails = {}
        Dir.entries(@list.emails).each do |filename|
          next if File.directory?(filename)
          # TODO: stop duplicating calls to preamble, store in memory
          yaml, body = preamble(full_path(filename))
          if yaml && yaml['day'] && yaml['key']
            emails[yaml['day']] = filename
          end
        end
        emails
      end
    end

    def preamble(path)
      Preamble.load(path)
    rescue
      [{}, File.read(path)]
    end
  end

  class Config
    include MemoryResource
    attr_resource :dev_email,
      :stripe_api_key,
      :download_dir,
      :download_path,
      :db_options,
      :email_options
  end

  class Product
    include MemoryResource
    attr_resource :from, :files, :price
  end

  class List
    include MemoryResource
    attr_resource :from, :emails, :url

    def subscribers
      Subscriber.all(list_key: self.key)
    end

    def subscribe_url
      url = URI.parse(self.url)
      params = [url.query]
      params << "boutique=subscribe/#{CGI.escape(self.key)}"
      url.query = params.compact.join('&')
      url.to_s
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
    property :confirmed, Boolean
    property :created_at, DateTime
    property :drip_on, Date, required: true
    property :drip_day, Integer, required: true, default: 0

    validates_within :list_key, set: List
    validates_uniqueness_of :email, scope: :list_key

    has n, :emails

    def initialize(*args)
      super
      self.secret ||= Digest::SHA1.hexdigest("#{rand(1000)}-#{Time.now}")[0..6]
      self.drip_on ||= Date.today
    end

    def list
      @list ||= List[self.list_key]
    end

    def confirm!(secret)
      self.confirmed = true if self.secret == secret
      self.save
    end

    def unconfirm!(secret)
      self.confirmed = false if self.secret == secret
      self.save
    end

    def confirm_url
      secret_url("confirm")
    end

    def unsubscribe_url
      secret_url("unsubscribe")
    end

    private
    def secret_url(action)
      url = URI.parse(self.list.url)
      params = [url.query]
      params << "boutique=#{action}/#{CGI.escape(self.list_key)}/#{self.id}/#{self.secret}"
      url.query = params.compact.join('&')
      url.to_s
    end
  end

  class Email
    include DataMapper::Resource

    property :id, Serial
    property :email_key, String, required: true
    property :created_at, DateTime

    validates_uniqueness_of :email_key, scope: :subscriber
    validates_presence_of :subscriber

    belongs_to :subscriber
  end

  DataMapper.finalize

  class App < Sinatra::Base
    set :raise_errors, false
    set :show_exceptions, false

    error do
      Pony.mail(
        :to => Boutique.config.dev_email,
        :subject => 'Boutique Error',
        :body => request.env['sinatra.error'].to_s
      ) if Boutique.config.dev_email
    end

    post '/subscribe/:list_key' do
      list = get_list(params[:list_key])
      subscriber = Subscriber.first_or_create(
        list_key: list.key,
        email: params[:email])
      Emailer.new(list).deliver_zero(subscriber) rescue nil
      ''
    end

    post '/confirm/:list_key/:id/:secret' do
      list = get_list(params[:list_key])
      subscriber = get_subscriber(params[:id], list, params[:secret])
      subscriber.confirm!(params[:secret])
      ''
    end

    post '/unsubscribe/:list_key/:id/:secret' do
      list = get_list(params[:list_key])
      subscriber = get_subscriber(params[:id], list, params[:secret])
      subscriber.unconfirm!(params[:secret])
      ''
    end

    private
    def get_list(list_key)
      List[list_key] || halt(404)
    end

    def get_subscriber(id, list, secret)
      Subscriber.first(
        id: params[:id],
        list_key: list.key,
        secret: secret) || halt(404)
    end
  end
end

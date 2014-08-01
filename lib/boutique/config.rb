module Boutique
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

end

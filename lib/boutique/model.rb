module Boutique
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

  DataMapper::Model.raise_on_save_failure = true
  DataMapper.finalize
end

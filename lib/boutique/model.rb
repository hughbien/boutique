module Boutique
  class Migrate
    def self.run
      Sequel.extension :migration
      migration = Sequel.migration do
        change do
          create_table(:subscribers) do
            primary_key :id
            column :list_key, String, null: false
            column :email, String, null: false
            column :secret, String, null: false
            column :confirmed, TrueClass, null: false, default: false
            column :created_at, DateTime, null: false
            column :drip_on, Date, null: false
            column :drip_day, Integer, null: false, default: 0
          end

          create_table(:emails) do
            primary_key :id
            foreign_key :subscriber_id, :subscribers
            column :email_key, String, null: false
            column :created_at, DateTime, null: false
          end
        end
      end
      migration.apply(Boutique.database, :up)
      # re-parse the schema after table changes
      Subscriber.dataset = Subscriber.dataset
      Email.dataset = Email.dataset
    end
  end

  class Subscriber < Sequel::Model
    one_to_many :emails
    set_allowed_columns :list_key, :email

    def initialize(*args)
      super
      self.secret ||= Digest::SHA1.hexdigest("#{rand(1000)}-#{Time.now}")[0..6]
      self.drip_on ||= Date.today
      self.created_at ||= DateTime.now
    end

    def validate
      super
      errors.add(:list_key, 'is invalid') if !List.include?(list_key)
      errors.add(:email, 'is invalid') if email !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i

      count = self.class.
        where(list_key: list_key, email: email).
        exclude(id: id).
        count
      errors.add(:email, 'has already subscribed') if count > 0
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

  class Email < Sequel::Model
    many_to_one :subscriber

    def initialize(*args)
      super
      self.created_at ||= DateTime.now
    end

    def validate
      super
      errors.add(:subscriber_id, "can't be blank") if subscriber_id.nil?

      count = self.class.
        where(subscriber_id: subscriber_id, email_key: email_key).
        exclude(id: id).
        count
      errors.add(:email_key, 'has already been sent') if count > 0
    end
  end
end

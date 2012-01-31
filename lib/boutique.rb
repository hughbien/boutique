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
  VERSION = '0.0.7'

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

  class Config
    def self.dev_email(value=nil)
      @dev_email = value if !value.nil?
      @dev_email
    end

    def self.pem_cert_id(value=nil)
      @pem_cert_id = value if !value.nil?
      @pem_cert_id
    end

    def self.pem_private(value=nil)
      @pem_private = value if !value.nil?
      @pem_private
    end

    def self.pem_public(value=nil)
      @pem_public = value if !value.nil?
      @pem_public
    end

    def self.pem_paypal(value=nil)
      @pem_paypal = value if !value.nil?
      @pem_paypal
    end

    def self.download_path(value=nil)
      @download_path = value if !value.nil?
      @download_path
    end

    def self.download_dir(value=nil)
      @download_dir = value if !value.nil?
      @download_dir
    end

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

    def files(value=nil)
      @files = value if !value.nil?
      @files
    end

    def price(value=nil)
      @price = value if !value.nil?
      @price
    end

    def return_url(value=nil)
      @return_url = value if !value.nil?
      @return_url
    end

    def support_email(value=nil)
      @support_email = value if !value.nil?
      @support_email
    end

    def to_hash
      {:code => @code,
       :name => @name,
       :files => @files,
       :price => @price,
       :return_url => @return_url,
       :support_email => @support_email}
    end
  end

  class Product
    include DataMapper::Resource

    property :id, Serial
    property :code, String, :required => true, :unique => true
    property :name, String, :required => true, :unique => true
    property :files, CommaSeparatedList, :required => true
    property :price, Decimal, :required => true
    property :return_url, String, :required => true
    property :support_email, String, :required => true

    has n, :purchases
  end

  class Purchase
    include DataMapper::Resource

    property :id, Serial
    property :created_at, DateTime
    property :counter, Integer, :required => true
    property :secret, String, :required => true
    property :transaction_id, String
    property :email, String
    property :name, String
    property :completed_at, DateTime
    property :downloads, CommaSeparatedList

    belongs_to :product

    def initialize(attr = {})
      attr[:counter] ||= 0
      attr[:secret] ||= random_hash
      super
    end

    def complete(txn_id, email, name)
      self.transaction_id = txn_id
      self.email = email
      self.name = name
      self.completed_at = DateTime.now
      link_downloads!
    end

    def completed?
      !completed_at.nil? && !transaction_id.nil?
    end

    def maybe_refresh_downloads!
      if self.completed? &&
         (self.downloads.nil? ||
          self.downloads.any? {|d| !File.exist?(d) })
        self.link_downloads!
        self.save
      end
    end

    def link_downloads!
      return if !completed?
      self.downloads = product.files.map do |file|
        linked_file = "/#{Date.today.strftime('%Y%m%d')}-#{random_hash}/#{File.basename(file)}"
        full_dir = File.dirname("#{Boutique.config.download_dir}#{linked_file}")
        `mkdir -p #{full_dir}`
        `ln -s #{file} #{Boutique.config.download_dir}#{linked_file}`
        "#{Boutique.config.download_path}#{linked_file}"
      end
      self.counter += 1
    end

    def boutique_id
      (self.id.nil? || self.secret.nil?) ?
        raise('Cannot get boutique_id for unsaved purchase') :
        "#{self.id}-#{self.secret}"
    end

    def random_hash
      Digest::SHA1.hexdigest("#{DateTime.now}#{rand}")[0..9]
    end

    def send_mail
      raise 'Cannot send link to incomplete purchase' if !completed?
      Pony.mail(
        :to => self.email,
        :from => self.product.support_email,
        :subject => "#{self.product.name} Receipt",
        :body => "Thanks for purchasing #{self.product.name}!  " +
                 "To download it, follow this link:\n\n" +
                 "    #{self.product.return_url}?b=#{boutique_id}\n\n" +
                 "Please reply if you have any troubles.\n"
      )
    end

    def to_json
      {
        :id => id,
        :counter => counter,
        :completed => completed?,
        :name => product.name,
        :code => product.code,
        :downloads => downloads
      }.to_json
    end

    def paypal_form(notify_url)
      values = {
        :business => Boutique.config.pp_email,
        :cmd => '_xclick',
        :item_name => product.name,
        :item_number => product.code,
        :amount => product.price.to_f,
        :currency_code => 'USD',
        :notify_url => "#{notify_url}/#{boutique_id}",
        :return => "#{product.return_url}?b=#{boutique_id}",
        :cert_id => Boutique.config.pem_cert_id
      }
      {'action' => Boutique.config.pp_url,
       'cmd' => '_s-xclick',
       'encrypted' => encrypt(values)}
    end

    private
    def encrypt(values)  
      signed = OpenSSL::PKCS7::sign(
        OpenSSL::X509::Certificate.new(File.read(Boutique.config.pem_public)),
        OpenSSL::PKey::RSA.new(File.read(Boutique.config.pem_private), ''),
        values.map { |k,v| "#{k.to_s}=#{v.to_s}" }.join("\n"),
        [],
        OpenSSL::PKCS7::BINARY)  
      OpenSSL::PKCS7::encrypt(
        [OpenSSL::X509::Certificate.new(File.read(Boutique.config.pem_paypal))],
        signed.to_der,
        OpenSSL::Cipher::Cipher::new("DES3"),
        OpenSSL::PKCS7::BINARY).to_s.gsub("\n", "")  
    end  
  end

  DataMapper.finalize

  class App < Sinatra::Base
    set :raise_errors, false
    set :show_exceptions, false

    error do
      Pony.mail(
        :to => Boutique.config.dev_email,
        :from => "boutique@#{Boutique.config.dev_email.split('@')[1..-1]}",
        :subject => 'Production Exception',
        :body => request.env['sinatra.error'].to_s
      ) if Boutique.config.dev_email
    end

    post '/buy/:code' do
      product = Boutique::Product.first(:code => params[:code])
      if product.nil?
        halt(404, "product #{params[:code]} not found")
      end
      purchase = Boutique::Purchase.new
      product.purchases << purchase
      product.save
      form = purchase.paypal_form("http://#{request.host}/notify")
      "<!doctype html><html><head><title>Redirecting to PayPal...</title>" +
      "<meta charset='utf-8'></head><body>" +
      "<form name='paypal' method='post' action='#{form['action']}'>" +
      "<input type='hidden' name='cmd' value='#{form['cmd']}'>" +
      "<input type='hidden' name='encrypted' value='#{form['encrypted']}'>" +
      "<input type='submit' value='submit' style='visibility:hidden'>" +
      "</form><script>document.paypal.submit();</script></body></html>"
    end

    post '/notify/:boutique_id' do
      purchase = get_purchase(params[:boutique_id])
      if !purchase.completed? &&
         params['txn_id'] &&
         params['payment_status'] &&
         params['first_name'] &&
         params['payer_email'] &&
         params['receiver_email'] == Boutique.config.pp_email
        purchase.complete(params['txn_id'], params['payer_email'], params['first_name'])
        purchase.send_mail
        purchase.save
      end
      ''
    end

    post '/recover/:code' do
      product = Boutique::Product.first(:code => params[:code])
      purchase = product.purchases.first(:email => params['email']) if product
      if product.nil? || purchase.nil? || !purchase.completed?
        halt(404, "purchase #{params[:code]}/#{params['email']} not found")
      end
      purchase.send_mail
      purchase.boutique_id
    end

    get '/record/:boutique_id' do
      purchase = get_purchase(params[:boutique_id])
      purchase.maybe_refresh_downloads!
      params['jsonp'].nil? ?
        purchase.to_json :
        "#{params['jsonp']}(#{purchase.to_json})"
    end

    def get_purchase(boutique_id)
      id, secret = boutique_id.split('-')
      purchase = Boutique::Purchase.get(id)
      if purchase.nil? || purchase.secret != secret
        halt(404, "purchase #{params[:boutique_id]} not found")
      end
      purchase
    end
  end
end

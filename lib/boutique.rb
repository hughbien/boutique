require 'rubygems'
require 'sinatra/base'
require 'dm-core'
require 'dm-types'
require 'cgi'
require 'date'
require 'digest/sha1'
require 'json'
require 'openssl'

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

    def to_hash
      {:code => @code,
       :name => @name,
       :files => @files,
       :price => @price,
       :return_url => @return_url}
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
    property :downloads, CommaSeparatedList

    belongs_to :product

    def initialize(attr = {})
      attr[:counter] ||= 0
      attr[:secret] ||= Digest::SHA1.hexdigest("#{DateTime.now}#{rand}")[0..9]
      super
    end

    def complete(txn_id)
      self.transaction_id = txn_id
      self.completed_at = DateTime.now
      link_download!
    end

    def completed?
      !completed_at.nil? && !transaction_id.nil?
    end

    def link_download!
      return if !completed?
      self.downloads = product.files.map do |file|
        linked_file = "/#{Date.today.strftime('%Y%m%d')}-#{boutique_id}/#{File.basename(file)}"
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
        :amount => product.price,
        :currency_code => 'USD',
        :notify_url => "#{notify_url}/#{boutique_id}",
        :return => "#{product.return_url}?b=#{boutique_id}"
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
        values.map { |k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join("\n"),
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
    get '/boutique/buy/:code' do
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
      "<form name='paypal' action='#{form['action']}'>" +
      "<input type='hidden' name='cmd' value='#{form['cmd']}'>" +
      "<input type='hidden' name='encrypted' value='#{form['encrypted']}'>" +
      "<input type='submit' value='submit' style='visibility:hidden'>" +
      "</form><script>document.paypal.submit();</script></body></html>"
    end

    get '/boutique/notify/:boutique_id' do
      purchase = get_purchase(params[:boutique_id])
      if params['txn_id'] &&
         params['payment_status'] &&
         params['receiver_email'] == Boutique.config.pp_email
        purchase.complete(params[:txn_id])
        purchase.save
      end
      ''
    end

    get '/boutique/record/:boutique_id' do
      json = get_purchase(params[:boutique_id]).to_json
      params['jsonp'].nil? ?
        json :
        "#{params['jsonp']}(#{json})"
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

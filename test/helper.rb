require File.expand_path('../lib/boutique', File.dirname(__FILE__))
require 'dm-migrations'
require 'minitest/autorun'
require 'rack'
require 'rack/test'
require 'rack/server'
require 'fileutils'

DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.auto_migrate!

module Pony
  def self.mail(fields)
    @last_mail = fields
  end

  def self.last_mail
    @last_mail
  end
end

class BoutiqueTest < MiniTest::Unit::TestCase
  def setup
    Boutique::Purchase.all.destroy
    Boutique::Product.all.destroy
    Boutique.configure(false) do |c|
      c.pem_private   File.expand_path('../certs/private.pem', File.dirname(__FILE__))
      c.pem_public    File.expand_path('../certs/public.pem', File.dirname(__FILE__))
      c.pem_paypal    File.expand_path('../certs/paypal.pem', File.dirname(__FILE__))
      c.download_path '/download'
      c.download_dir  File.expand_path('../temp', File.dirname(__FILE__))
      c.db_adapter    'sqlite3'
      c.db_host       'localhost'
      c.db_username   'root'
      c.db_password   'secret'
      c.db_database   'db.sqlite3'
      c.pp_email      'paypal_biz@mailinator.com'
      c.pp_url        'http://localhost'
    end
    Pony.mail(nil)
  end

  def teardown
    FileUtils.rm_rf(File.expand_path('../temp', File.dirname(__FILE__)))
  end

  private
  def ebook_product
    Boutique::Product.new(
      :code => 'ebook',
      :name => 'Ebook',
      :files => [File.expand_path('../README.md', File.dirname(__FILE__))],
      :price => 10.5,
      :return_url => 'http://zincmade.com',
      :support_email => 'support@zincmade.com')
  end
end

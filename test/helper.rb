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
    Boutique::Subscriber.all.destroy
    Boutique::List.reset_db
    Boutique::Product.reset_db
    Boutique.configure(false) do |c|
      c.email          'dev@localhost'
      c.stripe_api_key 'sk_test_abcdefghijklmnopqrstuvwxyz'
      c.download_path  '/download'
      c.download_dir   File.expand_path('../temp', File.dirname(__FILE__))
      c.db_adapter     'sqlite3'
      c.db_host        'localhost'
      c.db_username    'root'
      c.db_password    'secret'
      c.db_database    'db.sqlite3'
    end
    Pony.mail(nil)
  end

  def teardown
    FileUtils.rm_rf(File.expand_path('../temp', File.dirname(__FILE__)))
  end

  private
  def new_list
    Boutique.list('learn-icon') do |l|
      l.from   'learn-icon@example.com'
      l.emails '/path/to/emails-dir'
    end
    Boutique::List['learn-icon']
  end

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

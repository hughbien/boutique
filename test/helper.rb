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

class BoutiqueTest < MiniTest::Test
  def setup
    Boutique::Purchase.all.destroy
    Boutique::Subscriber.all.destroy
    Boutique::List.reset_db
    Boutique::Product.reset_db
    Boutique.configure(false) do |c|
      c.dev_email      'dev@localhost'
      c.stripe_api_key 'sk_test_abcdefghijklmnopqrstuvwxyz'
      c.download_path  '/download'
      c.download_dir   File.expand_path('../temp', File.dirname(__FILE__))
      c.db_options(adapter: 'sqlite3',
        host: 'localhost',
        username: 'root',
        password: 'secret',
        database: 'db.sqlite3')
      c.email_options(via: :sendmail)
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
      l.emails File.expand_path('../emails', File.dirname(__FILE__))
      l.url    'http://example.com'
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

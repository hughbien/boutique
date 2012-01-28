require File.expand_path('../lib/boutique', File.dirname(__FILE__))
require 'dm-migrations'
require 'minitest/autorun'
require 'rack'
require 'rack/test'
require 'rack/server'

DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.auto_migrate!

class BoutiqueTest < MiniTest::Unit::TestCase
  def setup
    Boutique::Purchase.all.destroy
    Boutique::Product.all.destroy
    Boutique.configure do |c|
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
  end

  private
  def ebook_product
    Boutique::Product.new(
      :code => 'ebook',
      :name => 'Ebook',
      :files => [File.expand_path('../README.md', File.dirname(__FILE__))],
      :price => 10.5,
      :return_url => 'http://zincmade.com')
  end
end

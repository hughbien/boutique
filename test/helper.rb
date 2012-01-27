require File.expand_path('../lib/boutique', File.dirname(__FILE__))
require 'dm-migrations'
require 'minitest/autorun'
require 'rack'
require 'rack/test'
require 'rack/server'

DataMapper.setup(:default, 'sqlite::memory:')
DataMapper.auto_migrate!

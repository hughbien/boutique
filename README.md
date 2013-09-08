Description
===========

Boutique is a Sinatra app for selling digital goods and drip email campaigns.

Installation
============

    $ gem install boutique

Setup a `config.ru` file and run it like any other Sinatra app:

    require 'rubygems'
    require 'boutique'

    Boutique.configure do |c|
      c.dev_email      'dev@mailinator.com'
      c.stripe_api_key 'sk_test_abcdefghijklmnopqrstuvwxyz'
      c.download_dir   '/path/to/download'
      c.download_path  '/download'

      c.db_options(adapter: 'postgresql', host: 'localhost',
        username: 'root', password: 'secret', database: 'boutique')
      c.email_options(via: :smtp, via_options: {host: 'smtp.example.org'})
    end

    Boutique.product('my-ebook') do |p|
      p.from  'Hugh <hugh@mailinator.com>'
      p.files '/path/to/ebook.zip'  # array for multiple files
      p.price 20
    end

    Boutique.list('learn-ruby') do |l|
      l.from   'Hugh <hugh@mailinator.com>'
      l.emails '/path/to/emails-dir'
      l.url    'http://example.com'
    end

    run Boutique::App if !ENV['BOUTIQUE_CMD']

Stick this in your `bashrc` or `zshrc`:

    BOUTIQUE_CONFIG='/path/to/config.ru'

Now setup the database tables (assuming you've already created the database and
credentials):

    $ boutique --migrate

Development
===========

Tests are setup to run individually via `ruby test/*_test.rb` or run them all
via `rake`.

TODO
====

* add re-usable UI for email subscription, confirmation, unsubscribe
* add ability to customize CSS of UI
* handle re-subscribers
* switch to Stripe
* add customizable? email integration for purchase receipts + recover
* add re-usable UI for purchasing, downloading, recover

License
=======

Copyright Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.

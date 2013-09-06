Description
===========

Boutique is a Sinatra app for selling digital goods and running drip mailing
lists.

Installation
============

    $ gem install boutique

Setup a `config.ru` file and run it like any other Sinatra app:

    require 'rubygems'
    require 'boutique'

    Boutique.configure do |c|
      c.email          'dev@mailinator.com'
      c.stripe_api_key 'sk_test_abcdefghijklmnopqrstuvwxyz'
      c.download_dir   '/path/to/download'
      c.download_path  '/download'
      c.db_adapter     'postgresql'
      c.db_host        'localhost'
      c.db_username    'root'
      c.db_password    'secret'
      c.db_database    'boutique'
    end

    Boutique.product('my-ebook') do |p|
      p.from  'Hugh <hugh@mailinator.com>'
      p.files '/path/to/ebook.zip'  # array for multiple files
      p.price 20
    end

    Boutique.list('learn-ruby') do |l|
      l.from       'Hugh <hugh@mailinator.com>'
      l.emails     '/path/to/emails-dir'
    end

    run Boutique::App if !ENV['BOUTIQUE_CMD']

Stick this in your `bashrc` or `zshrc`:

    BOUTIQUE_CONFIG='/path/to/config.ru'

Now setup the database tables (assuming you've already created the database and
credentials):

    $ boutique --migrate

Generate a JavaScript file and include it in your project:

    $ boutique --javascript > boutique.js

On your front-end, to trigger the modal:

    $("#product-buy-button").click(function(e) {
      e.preventDefault();
      Boutique.product('my-ebook', {
        name: "My Ebook",
        desc: "Get the ebook now",
        button: "Purchase Now"
      });
    });

    $("#email-subscribe-button").click(function(e) {
      e.preventDefault();
      Boutique.list('learn-ruby', {
        name: "Learn Ruby Email Course",
        desc: "Get a weekly email about learning Ruby.",
        button: "Subscribe Now"
      });
    });

The modal is dynamically constructed, so feel free to A/B test the copy used
for headlines and call to actions.

Usage
=====

The web application is for customers, to get information about your products use
the included command line application.

    $ boutique --stats my-ebook
    $ boutique --expire
    $ boutique --expire id
    $ boutique --delete id

Development
===========

Tests are setup to run individually via `ruby test/*_test.rb` or run them all
via `rake`.

TODO
====

* add confirm/unsubscribe actions
* add amazon SES integration for subscribe/confirm/unsubscribe
* add email rendering
* add email guard for subscribers (guard against duplicate email)
* add SES drip email support
* add single email blast support
* add SES integration for purchase receipts
* add re-usable UI for subscribe/confirmation/error
* add action button for subscribing reward?
* switch to Stripe
* add re-usable UI for purchase/recover/confirmation/error

License
=======

Copyright Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.

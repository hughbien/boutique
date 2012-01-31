Description
===========

Boutique is a Sinatra module for selling digital goods.  Still under development.

Installation
============

    % gem install boutique

You'll need some private/public certificates:

    % openssl genrsa -out private.pem 1024
    % openssl req -new -key private.pem -x509 -days 365 -out public.pem

Make sure the email you use is the same as your PayPal merchant email, or else
PayPal will reject it.

You can download PayPal's public certificate under `Profile > Encrypted
Payment Settings`.  Click the download button for PayPal Public Certificate.
Rename this certificate to something like `paypal.pem`.

While you're there, upload the `public.pem` certificate you just generated.  Copy
the `Cert ID`, you'll use it for the `pem_cert_id` field in your config.  You
can block unencrypted requests from `Website Payment Preferences`.

Setup a `config.ru` file and run it like any other Sinatra application.  You
can configure what products you sell here:

    require 'rubygems'
    require 'boutique'

    Boutique.configure do |c|
      c.dev_email      'dev@mailinator.com'
      c.pem_cert_id    'LONGCERTID'
      c.pem_private    '/path/to/private.pem'
      c.pem_public     '/path/to/public.pem'
      c.pem_paypal     '/path/to/paypal.pem'
      c.download_dir   '/path/to/download'
      c.download_path  '/download'
      c.db_adapter     'mysql'
      c.db_host        'localhost'
      c.db_username    'root'
      c.db_password    'secret'
      c.db_database    'boutique'
      c.pp_email       'paypal_biz@mailinator.com'
      c.pp_url         'https://www.sandbox.paypal.com/cgi-bin/webscr'
    end

    Boutique.product('icon-set') do |p|
      p.name       'Icon Set'
      p.files      '/path/to/icon-set.tgz'  # array for multiple files
      p.price      10.5
      p.return_url 'http://zincmade.com/thankyou'
    end

    run Boutique::App if !ENV['BOUTIQUE_CMD']

Stick this in your `bashrc` or `zshrc`:

    BOUTIQUE_CONFIG='/path/to/config.ru'

Now setup the database tables (assuming you've already created the database and
credentials):

    % boutique --migrate

With the settings above, a normal flow would look like:

1. On your site, link the user to `/buy/icon-set/` to purchase
2. User is redirected to paypal
3. After completing paypal, user is redirected to 
   `http://zincmade.com/thankyou?b=order-id`
4. On this page, issue an AJAX request to `/purchases/order-id`.
   The `downloads` field of the JSON will include the download URLs.

Usage
=====

The web application is for customers, to get information about your products use
the included command line application.

    % boutique --stats productcode
    % boutique --expire
    % boutique --expire id
    % boutique --delete id

Development
===========

Tests are setup to run individually via `ruby test/*_test.rb` or run them all
via `rake`.

TODO
====

* BUG: logs are required especially for errors

License
=======

Copyright 2011 Hugh Bien - http://hughbien.com.
Released under MIT License, see LICENSE.md for more info.

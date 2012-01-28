Description
===========

Boutique is a Sinatra module for selling digital goods.  Still under development.

Installation
============

    % gem install boutique

Setup a `config.ru` file and run it like any other Sinatra application.  You
can configure what products you sell here:

    require 'rubygems'
    require 'boutique'

    Boutique.configure do |c|
      c.store_path    'boutique'
      c.download_path 'download'
      c.paypal_key    'paypalapikey'
      c.db_username   'username'
      c.db_password   'password'
    end

    Boutique.product('icon-set') do |p|
      p.file        '/home/hugh/icon-set.tgz'
      p.price       10.5
      p.return_url  'http://zincmade.com/'
    end

    run Boutique::App

With the settings above, a normal flow would look like:

1. On your site, link the user to `/boutique/icon-set/` to purchase
2. User is redirected to paypal
3. After completing paypal, user is redirected to 
   `http://zincmade.com/?f=id-longhash`
4. On this page, issue an AJAX request to `/boutique/purchases/id-longhash`.
   The `download` field of the JSON will include the download URL.

Usage
=====

The web application is for customers, to get information about your products use
the included command line application.

    % boutique --list
    % boutique --stats key --after date --before date
    % boutique --clean

Development
===========

The `config.ru` is for local development.  Start the server via `shotgun`
command.  Tests are setup to run individually via `ruby test/*_test.rb` or
run them all via `rake`.

TODO
====

[ ] certificate/encrypted support
[ ] boutique command line
[ ] initial migration support
[ ] email customer
[ ] email exceptions to developer

License
=======

Copyright 2011 Hugh Bien - http://hughbien.com.
Released under MIT License, see LICENSE.md for more info.

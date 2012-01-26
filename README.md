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

    Boutique.add('Icon Set') do |p|
      p.id          'icon-set'
      p.file        '/home/hugh/icon-set.tgz'
      p.price       10.5
      p.return_url  'http://zincmade.com/'
      p.description '50 different icons in three sizes and four colors'
    end

    # start purchase at /boutique/icon-set/
    # download page at  /boutique/long-random-hex-hash/
    # actual file at    /download/long-random-hex-hash/icon-set.tgz
    run Boutique::App

Usage
=====

The web application is for customers, to get information about your products use
the included command line application.

    % boutique --list
    % boutique --stats id --after date --before date

Development
===========

The `config.ru` is for local development.  Start the server via `shotgun`
command.  Tests are setup to run individually via `ruby test/*_test.rb` or
run them all via `rake`.

License
=======

Copyright 2011 Hugh Bien - http://hughbien.com.
Released under MIT License, see LICENSE.md for more info.

# Description

Boutique is a Sinatra app for drip emails (and soon-to-be product checkouts).
Still in development!

# Installation

    $ gem install boutique

Setup a `config.ru` file and run it like any other Sinatra app:

    require 'rubygems'
    require 'boutique'

    Boutique.configure do |c|
      c.error_email    'dev@mailinator.com'
      c.stripe_api_key 'sk_test_abcdefghijklmnopqrstuvwxyz'
      c.download_dir   '/path/to/download'
      c.download_path  '/download'

      c.db_options(adapter: 'postgres', host: 'localhost',
        username: 'root', password: 'secret', database: 'boutique')
      c.email_options(via: :smtp, via_options: {host: 'smtp.example.org'})
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
credentials) and stick the `.css` and `.js` files in your project.  Note that
`boutique.js` is dependent on jQuery.

    $ bin/boutique --migrate
    $ boutique --assets
       new -- boutique.js
       new -- boutique.css
    $ mv boutique.js boutique.css /path/to/project/assets/.

# Drip Emails

Emails can be written in any templating format that `Tilt` accepts.  Stick them
in `/path/to/emails-dir` (configured above in `config.ru`).  Emails use
front-matter YAML for passing information to Boutique.  The required fields are
`day`, `subject`, and `key`.  The day is how many days should pass until the
email is sent.  The key is a unique key assigned to each email to guard against
sending multiples to the same recipient.  You'll also have access to three
local variables:

* `subscribe_url` - URL to open subscribe UI
* `confirm_url` - URL for double opt-in confirmation
* `unsubscribe_url` - URL to unsubscribe in one click

Here's an example email:

    ---
    day: 1
    subject: First Email
    key: first-email
    ---

    Hi,

    This is the first email in the series.

    Thanks,
    - Hugh

    [Click here to unsubscribe.](<%= unsubscribe_url %>)

This will be in the file `/path/to/emails-dir/first-email.md.erb`.  Based on
the file extensions, Boutique will run it through ERB first followed by Markdown.

Also note, the directory should contain a special **zero day** email.  This is
the email used to confirm when a new person signs up, also called the double
opt-in email:

    ---
    day: 0
    subject: Please confirm your email address
    key: confirm-email
    ---

    Hi,

    Thanks for signing up.  But wait, you're not done yet!  Please
    [click here to confirm your email address.](<%= confirm_url %>)

    If you subscribed or received this email by mistake, please feel free to
    ignore it.  You will not receive any further emails.

    Thanks!
    - Hugh

Emails are sent out using the command line tool `boutique --drip`.  This should
be run everyday.  It's idempotent, so it's fine if it gets run multiple times a
day by mistake.  Use cron to schedule drips:

    $ crontab -e
    0 8 * * * boutique --drip

# Development

Run all tests with `rake`.

Run individual tests with `ruby path/to/test.rb` or `rake TEST=path/to/test.rb`.

To start the server for local development:

    $ BOUTIQUE_DEV=1 shotgun

# TODO

* switch to SecureRandom
* add docs for using rack-timeout and rack-throttle
* add Stripe integration
* add template-able email integration for purchase receipts + recover
* add re-usable UI for purchasing, downloading, recover

# License

Copyright Hugh Bien - http://hughbien.com.
Released under BSD License, see LICENSE.md for more info.

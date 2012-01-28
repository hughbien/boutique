require File.expand_path('lib/boutique', File.dirname(__FILE__))

Boutique.configure(false) do |c|
  c.pem_private   File.expand_path('certs/private.pem', File.dirname(__FILE__))
  c.pem_public    File.expand_path('certs/public.pem', File.dirname(__FILE__))
  c.pem_paypal    File.expand_path('certs/paypal.pem', File.dirname(__FILE__))
  c.download_path '/download'
  c.download_dir  File.expand_path('temp', File.dirname(__FILE__))
  c.db_adapter    'sqlite3'
  c.db_host       'localhost'
  c.db_username   'root'
  c.db_password   'secret'
  c.db_database   'db.sqlite3'
  c.pp_email      'paypal_biz@mailinator.com'
  c.pp_url        'http://localhost'
end

run Boutique::App

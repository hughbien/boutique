require File.expand_path('helper', File.dirname(__FILE__))
require 'redcarpet'

class EmailTest < BoutiqueTest
  def test_render
    list = new_list
    emailer = Boutique::Emailer.new(list)
    emailer.render(
      'intro.md.erb',
      confirm_url: 'http://example.org/confirm',
      unsubscribe_url: 'http://example.org/unsubscribe')
  end

  def test_send
    list = new_list
    emailer = Boutique::Emailer.new(list)
    emailer.send('intro.md.erb')
    refute(Pony.last_mail)

    Boutique::Subscriber.create(
      list_key: list.key, email: 'john@mailinator.com', confirmed: true)
    emailer.send('intro.md.erb')
    mail = Pony.last_mail
    assert_equal('john@mailinator.com', mail[:to])
    assert_equal('learn-icon@example.com', mail[:from])
    assert_equal('Welcome to Boutique', mail[:subject])
    refute_nil(mail[:body])
  end
end

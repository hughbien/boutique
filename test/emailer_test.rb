require File.expand_path('helper', File.dirname(__FILE__))
require 'redcarpet'

class EmailerTest < BoutiqueTest
  def test_render
    list = new_list
    emailer = Boutique::Emailer.new(list)
    emailer.render(
      'intro.md.erb',
      confirm_url: 'http://example.org/confirm',
      unsubscribe_url: 'http://example.org/unsubscribe')
  end

  def test_blast
    list = new_list
    emailer = Boutique::Emailer.new(list)
    emailer.blast('intro.md.erb')
    refute(Pony.last_mail)
    assert_equal(0, Boutique::Email.count)

    Boutique::Subscriber.create(
      list_key: list.key, email: 'john@mailinator.com', confirmed: true)
    emailer.blast('intro.md.erb')
    mail = Pony.last_mail
    assert_equal('john@mailinator.com', mail[:to])
    assert_equal('learn-icon@example.com', mail[:from])
    assert_equal('Welcome to Boutique', mail[:subject])
    refute_nil(mail[:body])
    assert_equal(1, Boutique::Email.count)

    Pony.mail(nil)
    assert_raises(RuntimeError) { emailer.blast('intro.md.erb') }
    assert_nil(Pony.last_mail)
    assert_equal(1, Boutique::Email.count)
  end
end

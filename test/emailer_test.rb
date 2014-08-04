require_relative 'helper'
require 'redcarpet'

class EmailerTest < BoutiqueTest
  def setup
    super
    @list = new_list
    @emailer = Boutique::Emailer.new(@list)
  end

  def test_render
    @emailer.render(
      'intro.md.erb',
      confirm_url: 'http://example.org/confirm',
      unsubscribe_url: 'http://example.org/unsubscribe')
  end

  def test_blast
    @emailer.blast('first.md.erb')
    refute(Pony.last_mail)
    assert_equal(0, Boutique::Email.count)

    create_subscriber
    @emailer.blast('first.md.erb')
    mail = Pony.last_mail
    assert_equal('john@mailinator.com', mail[:to])
    assert_equal('learn-icon@example.com', mail[:from])
    assert_equal('First Email', mail[:subject])
    refute_nil(mail[:body])
    assert_equal(1, Boutique::Email.count)

    Pony.mail(nil)
    @emailer.blast('first.md.erb')
    assert_nil(Pony.last_mail)
    assert_equal(1, Boutique::Email.count)
  end

  def test_drip
    @emailer.drip
    refute(Pony.last_mail)
    assert_equal(0, Boutique::Email.count)

    subscriber = create_subscriber
    subscriber.drip_on = Date.today - 1
    subscriber.save
    assert_equal(0, subscriber.drip_day)
    @emailer.drip
    subscriber = Boutique::Subscriber[subscriber.id]
    assert_equal(1, subscriber.drip_day)
    refute_nil(Pony.last_mail)
    assert_equal(1, Boutique::Email.count)
    assert_equal('first', Boutique::Email.first.email_key)

    Pony.mail(nil)
    @emailer.drip
    subscriber = Boutique::Subscriber[subscriber.id]
    assert_equal(1, subscriber.drip_day)
    assert_nil(Pony.last_mail)
    assert_equal(1, Boutique::Email.count)
  end

  private
  def create_subscriber
    subscriber = Boutique::Subscriber.new(list_key: @list.key, email: 'john@mailinator.com')
    subscriber.confirmed = true
    subscriber.save
    subscriber
  end
end

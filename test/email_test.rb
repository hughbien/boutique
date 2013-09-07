require File.expand_path('helper', File.dirname(__FILE__))
require 'redcarpet'

class EmailTest < BoutiqueTest
  def test_render
    list = new_list
    emailer = Boutique::Emailer.new(list.emails)
    emailer.render(
      'intro.md.erb',
      confirm_url: 'http://example.org/confirm',
      unsubscribe_url: 'http://example.org/unsubscribe')
  end
end

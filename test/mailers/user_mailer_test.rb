#   Copyright (c) 2012-2017, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

require 'test_helper'

class UserMailerTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  let(:sender) { create :user }
  let(:receiver) { create :legal_entity }
  let(:text) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.' }

  it '#contact' do
    mail = UserMailer.contact(sender: sender, resource_id: receiver.id, text: text)

    expect(mail).must deliver_to receiver.email
    value(mail.subject).must_equal('[Nachbarschaftsmarktplatz] ein/e Nutzer*in hat eine Frage an Dich')
    expect(mail).must have_body_text sender.nickname
    expect(mail).must have_body_text user_url sender.id
    expect(mail).must have_body_text sender.email
    expect(mail).must have_body_text ' hat Dir eine Frage gestellt:'
    expect(mail).must have_body_text text
  end
end

#   Copyright (c) 2012-2017, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

require 'test_helper'

class CartMailerTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  it 'sends email to seller' do
    seller_line_item_group = create(:line_item_group, :with_business_transactions, :sold, create_line_items: true)
    user = seller_line_item_group.seller
    mail = CartMailer.seller_email(seller_line_item_group)
    expect(mail).must deliver_to(user.order_notifications_email)
  end

  describe 'CartMailer#buyer_email' do
    let(:cart) do
      create :cart, :with_line_item_groups_from_legal_entity, user: create(:user), sold: true
    end

    it 'sends email to buyer' do
      user = cart.user
      mail = CartMailer.buyer_email(cart)
      expect(mail).must deliver_to(user.email)
    end

    it 'must contain courier terms when at least one transaction has
        selected_transport bike_courier' do
      create :business_transaction, line_item_group_id: cart.line_item_groups.first.id
      BusinessTransaction.any_instance.stubs(:selected_transport)
        .returns('bike_courier')
      mail = CartMailer.buyer_email(cart)

      # Attachment
      attachment = mail.attachments['fahrwerk_kurierkollektiv_agb.pdf']
      value(attachment.filename).must_equal 'fahrwerk_kurierkollektiv_agb.pdf'
    end
  end

  it 'sends email to courier service' do
    business_transaction = create :business_transaction, :transport_bike_courier, :paypal, state: 'ready'
    create :paypal_payment, line_item_group: business_transaction.line_item_group, state: 'confirmed'
    seller          = business_transaction.seller
    buyer           = business_transaction.buyer
    mail            = CartMailer.courier_notification(business_transaction)

    expect(mail).must_deliver_to 'test@test.com'
    expect(mail).must_bcc_to 'bybike@fairmondo.de'

    # Article information
    expect(mail).must have_body_text(business_transaction.article_title)

    # Seller information
    expect(mail).must have_subject('[Nachbarschaftsmarktplatz] Artikel ausliefern')
    expect(mail).must have_body_text(seller.fullname)
    expect(mail).must have_body_text(seller.standard_address_first_name)
    expect(mail).must have_body_text(seller.standard_address_last_name)
    expect(mail).must have_body_text(seller.standard_address_address_line_1)
    expect(mail).must have_body_text(seller.standard_address_address_line_1)
    expect(mail).must have_body_text(seller.standard_address_city)
    expect(mail).must have_body_text(seller.standard_address_zip)

    # Buyer information
    expect(mail).must have_body_text(buyer.fullname)
    expect(mail).must have_body_text(buyer.standard_address_first_name)
    expect(mail).must have_body_text(buyer.standard_address_last_name)
    expect(mail).must have_body_text(buyer.standard_address_address_line_1)
    expect(mail).must have_body_text(buyer.standard_address_address_line_1)
    expect(mail).must have_body_text(buyer.standard_address_city)
    expect(mail).must have_body_text(buyer.standard_address_zip)

    # Info about Transaction
    expect(mail).must have_body_text(business_transaction.bike_courier_time)
    expect(mail).must have_body_text(business_transaction.bike_courier_message)
  end

  describe 'sending email on voucher payment' do |_variable|
    it 'displays donated money' do
      payment = create :voucher_payment, pay_key: '999999999a'
      seller = payment.line_item_group.seller
      mail = CartMailer.voucher_paid_email(payment.id)
      expect(mail).must deliver_to(seller.email)
      expect(mail).must have_body_text 'Dadurch ist ein Spendenbetrag von'
    end

    it 'displays missing money' do
      payment = create :voucher_payment, pay_key: '1a'
      seller = payment.line_item_group.seller
      mail = CartMailer.voucher_paid_email(payment.id)
      expect(mail).must deliver_to(seller.email)
      expect(mail).must have_body_text 'werden von dem/der Käufer*in überwiesen'
    end
  end

  describe '#send_cart' do
    it 'sends open cart to specified email address' do
      cart = create :cart
      addr = 'test@test.com'
      mail = CartMailer.send_cart(cart.id, addr)

      expect(mail).must deliver_to(addr)
      expect(mail).must have_subject('[Nachbarschaftsmarktplatz] Deine vorgemerkten Artikel auf dem Nachbarschaftsmarktplatz')
    end
  end
end

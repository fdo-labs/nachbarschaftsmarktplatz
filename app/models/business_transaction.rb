# A transaction handles the purchase process of an article.
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#
class BusinessTransaction < ActiveRecord::Base
  extend Enumerize
  extend Sanitization

  include BusinessTransaction::Refundable, BusinessTransaction::Discountable, BusinessTransaction::Scopes

  belongs_to :article, inverse_of: :business_transaction
  belongs_to :buyer, class_name: 'User', foreign_key: 'buyer_id'
  belongs_to :seller, class_name: 'User', foreign_key: 'seller_id', inverse_of: :sold_business_transactions
  has_one :rating

  attr_accessor :updating_state, :updating_multiple

  auto_sanitize :message, :forename, :surname, :street, :address_suffix, :city, :zip, :country

  enumerize :selected_transport, in: Article::TRANSPORT_TYPES
  enumerize :selected_payment, in: Article::PAYMENT_TYPES

  delegate :title, :seller, :selectable_transports, :selectable_payments,
           :transport_provider, :transport_price, :payment_cash_on_delivery_price,
           :basic_price, :basic_price_amount, :basic_price_amount_text, :price,
           :price_without_vat, :total_price, :quantity, :quantity_left,
           :transport_type1_provider, :transport_type2_provider, :calculated_fair,
           :calculated_fair_cents, :calculated_fee, :calculated_fee_cents,
           :friendly_percent, :friendly_percent_organisation, :vat_price, :vat,
           :custom_seller_identifier, :number_of_shipments, :cash_on_delivery_price,
           :active?,
           to: :article, prefix: true
  delegate :email, :forename, :surname, :fullname, :nickname,
           to: :buyer, prefix: true
  delegate :email, :fullname, :nickname, :phone, :mobile, :address, :forename,
           :bank_account_owner, :bank_account_number, :bank_code, :bank_name,
           :about, :terms, :cancellation, :paypal_account,:ngo, :iban, :bic,
           :vacationing?,
           to: :article_seller, prefix: true
  delegate :value, to: :rating, prefix: true

  # CREATE
  #validates_inclusion_of :type, :in => ["MultipleFixedPriceBusinessTransaction", "PartialFixedPriceBusinessTransaction", "SingleFixedPriceBusinessTransaction", "PreviewBusinessTransaction"]
  validates :article, presence: true

  # UPDATE
  validates :tos_accepted, acceptance: { accept: true }, on: :update
  #validates :message, allow_blank: true, on: :update

  validates :buyer, presence: true, on: :update, if: :updating_state, unless: :multiple?
  with_options if: :updating_state, unless: :updating_multiple do |t|
    t.validates :selected_transport, supported_option: true, presence: true
    t.validates :selected_payment, supported_option: true, common_sense: true, presence: true

    t.validates :forename, presence: true
    t.validates :surname, presence: true
    t.validates :address_suffix, length: { maximum: 150 }
    t.validates :street, format: /\A.+\d+.*\z/, presence: true
    t.validates :city, presence: true
    t.validates :zip, zip: true, presence: true
    t.validates :country, presence: true
  end

  state_machine initial: :available do

    state :available do
    end

    state :sold do
    end

    state :paid do
    end

    state :sent do
    end

    state :completed do
    end

    event :buy do
      transition :available => :sold, if: :sold_out_after_buy?
      transition :available => same
    end

    event :pay do
      transition :sold => :paid
    end

    event :ship do
      transition :paid => :sent
    end

    event :receive do
      transition :sent => :completed
    end

    before_transition do |business_transaction, transition|
      # To be able to differentiate between updates by article modifications or state changes
      business_transaction.updating_state = true
    end

    before_transition on: :buy do |business_transaction, transition|
      business_transaction.sold_at = Time.now
    end
  end

  # Per default a transaction automatically is sold out after the first buy event, except for MultipleFPT
  def sold_out_after_buy?
    true
  end

  def deletable?
    available?
  end

  # Make virtual field validatable
  # @api public
  # @param value [String]
  # @return [Boolean]
  def tos_accepted= value
    @tos_accepted = (value == "1")
  end
  attr_reader :tos_accepted

  # Edit can be called with GET params. If they are valid, it renders a different
  # view to show the final sales price. This method is called to validates if the
  # params are valid.
  #
  # @api public
  # @param params [Hash] The GET parameters
  # @return [Boolean]
  def edit_params_valid? params
    validator_instance = create_validator_business_transaction params
    if validator_instance.valid?
      true
    else
      validator_instance.errors.each { |k,v| self.errors.add k, v }
      false
    end
  end

  # Get transport options that were selected by seller
  #
  # @api public
  # @return [Array] Array in 2 levels with option name and it's localization
  def selected_transports
    selected "transport"
  end

  # Get payment options that were selected by seller
  #
  # @api public
  # @return [Array] Array in 2 levels with option name and it's localization
  def selected_payments
    selected "payment"
  end

  # Find out if a specifictransport/payment type was selected by the seller
  # @api public
  # @param attribute [String] "transport" or "payment"
  # @param type [String] enumerize type to check
  # @return [Boolean]
  def selected? attribute, type
    filtered_array = selected(attribute).select {|a| a[1] == type }
    !filtered_array.empty?
  end

  # Shortcut for article_total_price working with saved data
  def total_price
    self.article_total_price(
      self.selected_transport,
      self.selected_payment,
      self.quantity_bought
    )
  end

  def multiple?
    is_a? MultipleFixedPriceTransaction
  end

  # Default behavior for associations in subclasses
  def parent; nil; end
  def children; []; end

  # TODO Check if there is a better way -> only used in export model
  def selected_transport_provider
    if self.selected_transport == "pickup"
      "pickup"
    elsif self.selected_transport == "type1"
      self.article.transport_type1_provider
    elsif self.selected_transport == "type2"
      self.article.transport_type2_provider
    end
  end

  protected
    # Disallow these fields in general. Will be overwritten for specific subclasses that need these fields.
    def quantity_available; raise NoMethodError; end
    def quantity_bought; raise NoMethodError; end

  private
    # Get attribute options that were selected on transaction's article
    #
    # @api private
    # @param attribute [String] "transport" or "payment" (enums that have a counter part in the article model)
    # @return [Array] Array in 2 levels with enum option name and it's localization
    def selected attribute
      selectables = send("article_selectable_#{attribute}s")
      BusinessTransaction.send("selected_#{attribute}").options.select { |e| selectables.include? e[1].to_sym }
    end

    # Create new instance to run validations on
    def create_business_transaction_validator params
      validator = self.class.new params
      validator.article = self.article
      validator.quantity_available = self.quantity_available if self.is_a? MultipleFixedPriceTransaction
      validator.updating_state = true
      validator
    end
end
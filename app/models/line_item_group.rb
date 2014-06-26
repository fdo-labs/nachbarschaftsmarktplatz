class LineItemGroup < ActiveRecord::Base
  belongs_to :seller, class_name: 'User', foreign_key: 'user_id', inverse_of: :line_item_groups
  belongs_to :cart, inverse_of: :line_item_groups
  has_many :line_items, dependent: :destroy, inverse_of: :line_item_group

  validates :unified_transport, inclusion: { in: -> { unified_transports_selectable } }, presence: true , if: :transport_can_be_unified?
  validates :unified_payment, inclusion: { in: -> { unified_payments_selectable } }, presence: true, if: :payment_can_be_unified?

  def transport_can_be_unified?
    unified_transports_selectable.any?
  end

  def unified_transports_selectable
    @unified_transports_selectable ||= ( self.line_items.map{|l| l.business_transaction.article.selectable_transports}.inject(:&) || [] )#intersection of selectable_transports
  end

  def payment_can_be_unified?
    unified_payments_selectable.any?
  end

  def unified_payments_selectable
    @unified_payments_selectable ||= ( self.line_items.map{|l| l.business_transaction.article.selectable_payments}.inject(:&) || [] ) #intersection of selectable_payments
  end

  def unified_transport= value
    super true
    set this on all transactions as well
    self.line_items.map(&:business_transaction).each do |t|
      t.selected_transport = value
    end
  end

  def unified_transport
    self.line_items.first.business_transaction.selected_transport if super && self.line_items.any?
  end

  def unified_payment= value
    super true
    set this on all transactions as well
    self.line_items.map(&:business_transaction).each do |t|
      t.selected_payment = value
    end
  end

  def unified_payment
    self.line_items.first.business_transaction.selected_payment if super && self.line_items.any?
  end


end

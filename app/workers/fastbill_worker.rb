#   Copyright (c) 2012-2017, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

class FastbillWorker
  include Sidekiq::Worker

  sidekiq_options queue: :fastbill,
                  retry: 20, # this means approx 6 days
                  backtrace: true

  # disable this worker since we are not working with fastbill
  # but keep this in place in case we decide to go back to a billing service of some kind
  def perform(id)
    #BusinessTransaction.transaction do
    #  bt = BusinessTransaction.lock.find(id)
      # check if bt is qualified for discount
    #  Discount.discount_chain(bt) if bt.article_discount_id
      # Start the fastbill chain, to create invoices and add items to invoice
    #  api = FastbillAPI.new(bt)
    #  api.fastbill_chain
    #end
  end
end

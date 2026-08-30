# frozen_string_literal: true

module Paypal
  class IpnMessage < ActiveRecord::Base
    belongs_to :race_entry, optional: true

    validates :raw_post, presence: true
    validates :txn_id, uniqueness: true, allow_nil: true

    def verified?
      verification_status == "verified"
    end

    # BigDecimal columns (mc_gross, mc_fee) render as e-notation ("0.45e2")
    # in the console by default; show money values plainly
    def format_for_inspect(name, value)
      value.is_a?(BigDecimal) ? value.to_s("F") : super
    end
  end
end

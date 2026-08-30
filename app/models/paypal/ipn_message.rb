# frozen_string_literal: true

module Paypal
  class IpnMessage < ActiveRecord::Base
    # Processing results that need human follow-up
    ATTENTION_RESULTS = %w[created_merch_size_unknown amount_mismatch invoice_unrecognized receiver_mismatch].freeze

    belongs_to :race_entry, optional: true

    validates :raw_post, presence: true
    validates :txn_id, uniqueness: true, allow_nil: true

    scope :needs_attention, -> { where(processing_result: ATTENTION_RESULTS) }

    def verified?
      verification_status == "verified"
    end

    def needs_attention?
      ATTENTION_RESULTS.include?(processing_result)
    end

    # BigDecimal columns (mc_gross, mc_fee) render as e-notation ("0.45e2")
    # in the console by default; show money values plainly
    def format_for_inspect(name, value)
      value.is_a?(BigDecimal) ? value.to_s("F") : super
    end
  end
end

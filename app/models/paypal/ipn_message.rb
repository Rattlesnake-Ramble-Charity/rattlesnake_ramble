# frozen_string_literal: true

module Paypal
  class IpnMessage < ActiveRecord::Base
    belongs_to :race_entry, optional: true

    validates :raw_post, presence: true
    validates :txn_id, uniqueness: true, allow_nil: true

    def verified?
      verification_status == "verified"
    end
  end
end

# frozen_string_literal: true

module Webhooks
  class PaypalIpnsController < ::ApplicationController
    # PayPal cannot supply a CSRF token; authenticity is established by the
    # verification postback inside Paypal::ProcessIpn instead
    skip_before_action :verify_authenticity_token

    def create
      result = ::Paypal::ProcessIpn.perform(raw_post: request.raw_post)

      send_payment_ack_and_schedule_reminders(result.race_entry) if result.entry_created?
      RaceMailer.ipn_attention_needed(result.ipn_message).deliver_later if result.needs_admin_attention?

      # A non-2xx response makes PayPal redeliver the message, which retries
      # transient verification failures for us
      result.retryable_error? ? head(:service_unavailable) : head(:ok)
    end
  end
end

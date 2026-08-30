# frozen_string_literal: true

module Paypal
  # Confirms that an IPN message is genuine by echoing it back to PayPal,
  # per the IPN protocol. PayPal responds VERIFIED for authentic messages
  # and INVALID for anything else.
  class VerifyIpn
    def self.perform(raw_post)
      new(raw_post).perform
    end

    def initialize(raw_post)
      @raw_post = raw_post
    end

    # Returns "verified", "invalid", or "error" (transient failure; retryable)
    def perform
      response = RestClient.post(
        verification_url,
        "cmd=_notify-validate&#{raw_post}",
        content_type: "application/x-www-form-urlencoded"
      )

      case response.body
      when "VERIFIED" then "verified"
      when "INVALID" then "invalid"
      else
        Rails.logger.error "Unexpected IPN verification response body: #{response.body}"
        "error"
      end
    rescue RestClient::Exception, SocketError, SystemCallError, Timeout::Error => e
      Rails.logger.error "IPN verification request failed: #{e.class}: #{e.message}"
      "error"
    end

    private

    attr_reader :raw_post

    def verification_url
      "#{Rails.application.secrets.paypal_ipnpb_host}/cgi-bin/webscr"
    end
  end
end

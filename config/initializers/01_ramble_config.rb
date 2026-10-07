# frozen_string_literal: true

# Thin accessor layer over config/ramble.yml (per-environment settings)
# and a few environment variables.
module RambleConfig
  def self.settings
    @settings ||= Rails.application.config_for(:ramble)
  end

  def self.home_time_zone
    "Mountain Time (US & Canada)"
  end

  def self.military_time_regex
    /\A\d{1,2}:\d{2}(:\d{2})?\z/
  end

  def self.paypal_business_email
    ENV["PAYPAL_BUSINESS_EMAIL"].presence || "bwright@rattlesnakeramble.org"
  end

  # PayPal checkout host.
  def self.paypal_host
    settings.fetch(:paypal_host)
  end

  # PayPal IPN verification host.
  def self.paypal_ipnpb_host
    settings.fetch(:paypal_ipnpb_host)
  end
end

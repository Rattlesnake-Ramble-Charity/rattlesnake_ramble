# frozen_string_literal: true

module RambleConfig
  def self.home_time_zone
    "Mountain Time (US & Canada)"
  end

  def self.military_time_regex
    /\A\d{1,2}:\d{2}(:\d{2})?\z/
  end

  def self.paypal_business_email
    ENV["PAYPAL_BUSINESS_EMAIL"].presence || "bwright@rattlesnakeramble.org"
  end

  def self.paypal_ipnpb_host
    Rails.application.secrets.paypal_ipnpb_host
  end
end

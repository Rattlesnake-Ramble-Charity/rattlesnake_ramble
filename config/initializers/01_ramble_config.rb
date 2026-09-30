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

  # Base URL of this site, with a trailing slash. Used to build the return
  # and notify URLs handed to PayPal.
  def self.app_host
    case Rails.env
    when "production" then "https://www.rattlesnakeramble.org/"
    when "test" then "http://www.example.com/"
    else "http://localhost:3000/"
    end
  end

  # PayPal checkout host (live in production, sandbox everywhere else).
  def self.paypal_host
    Rails.env.production? ? "https://www.paypal.com" : "https://www.sandbox.paypal.com"
  end

  # PayPal IPN verification host.
  def self.paypal_ipnpb_host
    case Rails.env
    when "production" then "https://ipnpb.paypal.com"
    when "test" then "https://ipnpb.example.com"
    else "https://ipnpb.sandbox.paypal.com"
    end
  end
end

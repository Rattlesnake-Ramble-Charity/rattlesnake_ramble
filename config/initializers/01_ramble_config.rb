# frozen_string_literal: true

module RambleConfig
  def self.home_time_zone
    "Mountain Time (US & Canada)"
  end

  def self.military_time_regex
    /\A\d{1,2}:\d{2}(:\d{2})?\z/
  end

  def self.ost_email
    ENV["OST_EMAIL"]
  end

  def self.ost_password
    ENV["OST_PASSWORD"]
  end

  def self.ost_url
    ENV["OST_URL"].presence || "https://www.opensplittime.org"
  end

  def self.paypal_business_email
    ENV["PAYPAL_BUSINESS_EMAIL"].presence || "bwright@rattlesnakeramble.org"
  end
end

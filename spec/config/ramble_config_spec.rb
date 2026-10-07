# frozen_string_literal: true

require "rails_helper"

RSpec.describe RambleConfig do
  describe ".settings" do
    it "loads the current environment's section of config/ramble.yml" do
      expect(described_class.paypal_host).to eq("https://www.sandbox.paypal.com")
      expect(described_class.paypal_ipnpb_host).to eq("https://ipnpb.example.com")
    end
  end
end

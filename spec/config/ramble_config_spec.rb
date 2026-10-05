# frozen_string_literal: true

require "rails_helper"

RSpec.describe RambleConfig do
  describe ".default_url_options" do
    it "derives host and protocol from app_host, omitting a default port" do
      expect(described_class.app_host).to eq("http://www.example.com/")
      expect(described_class.default_url_options).to eq(host: "www.example.com", protocol: "http")
    end

    it "includes a non-default port" do
      allow(described_class).to receive(:app_host).and_return("http://localhost:3000/")
      expect(described_class.default_url_options).to eq(host: "localhost", protocol: "http", port: 3000)
    end
  end

  describe ".settings" do
    it "loads the current environment's section of config/ramble.yml" do
      expect(described_class.paypal_ipnpb_host).to eq("https://ipnpb.example.com")
    end
  end
end

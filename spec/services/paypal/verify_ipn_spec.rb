# frozen_string_literal: true

require "rails_helper"

RSpec.describe Paypal::VerifyIpn do
  subject { described_class.perform(raw_post) }

  let(:raw_post) { "txn_id=TXN001&payment_status=Completed" }

  context "when PayPal responds VERIFIED" do
    let(:response) { instance_double("RestClient::Response", body: "VERIFIED") }

    it "posts the message back with the validation command and returns verified" do
      expect(RestClient).to receive(:post).with(
        "https://ipnpb.example.com/cgi-bin/webscr",
        "cmd=_notify-validate&txn_id=TXN001&payment_status=Completed",
        content_type: "application/x-www-form-urlencoded"
      ).and_return(response)

      expect(subject).to eq("verified")
    end
  end

  context "when PayPal responds INVALID" do
    let(:response) { instance_double("RestClient::Response", body: "INVALID") }

    it "returns invalid" do
      allow(RestClient).to receive(:post).and_return(response)
      expect(subject).to eq("invalid")
    end
  end

  context "when PayPal responds with an unexpected body" do
    let(:response) { instance_double("RestClient::Response", body: "<html>maintenance</html>") }

    it "returns error" do
      allow(RestClient).to receive(:post).and_return(response)
      expect(subject).to eq("error")
    end
  end

  context "when the request raises" do
    it "returns error" do
      allow(RestClient).to receive(:post).and_raise(RestClient::Exception)
      expect(subject).to eq("error")
    end
  end
end

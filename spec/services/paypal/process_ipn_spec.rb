# frozen_string_literal: true

require "rails_helper"

RSpec.describe Paypal::ProcessIpn do
  subject { described_class.perform(raw_post: raw_post) }

  let(:raw_post) { URI.encode_www_form(ipn_fields) }

  let(:ipn_fields) do
    {
      txn_id: "TXN00000000000001",
      txn_type: "web_accept",
      payment_status: "Completed",
      mc_gross: "45.00",
      mc_fee: "1.61",
      mc_currency: "USD",
      invoice: "RaceEdition#{race_edition.id}-Racer#{racer.id}",
      item_name: race_edition.name,
      payer_email: "runner@example.com",
      first_name: "Jane",
      last_name: "Doe",
      receiver_email: RambleConfig.paypal_business_email,
      business: RambleConfig.paypal_business_email,
    }
  end

  let!(:race_edition) do
    FactoryBot.create(:race_edition, :full_course, date: "2027-09-18", entry_fee: 45, selling_merchandise: true, merchandise_price: 25)
  end

  let!(:racer) { FactoryBot.create(:racer, :female) }

  before { allow(Paypal::VerifyIpn).to receive(:perform).and_return("verified") }

  context "when the racer has no entry yet" do
    it "creates a paid race entry and records the message" do
      expect { subject }.to change(RaceEntry, :count).by(1)

      entry = RaceEntry.last
      expect(entry.racer).to eq(racer)
      expect(entry.race_edition).to eq(race_edition)
      expect(entry.paid).to eq(true)
      expect(entry.merchandise_size).to be_nil

      message = subject.ipn_message.reload
      expect(message.verification_status).to eq("verified")
      expect(message.processing_result).to eq("race_entry_created")
      expect(message.race_entry).to eq(entry)
    end

    it "returns a result reporting the created entry" do
      result = subject
      expect(result.entry_created?).to eq(true)
      expect(result.retryable_error?).to eq(false)
      expect(result.needs_admin_attention?).to eq(false)
      expect(result.race_entry).to eq(RaceEntry.last)
    end
  end

  context "when an unpaid entry already exists" do
    let!(:existing_entry) { FactoryBot.create(:race_entry, race_edition: race_edition, racer: racer, paid: false) }

    it "marks the entry paid without creating another" do
      expect { subject }.not_to change(RaceEntry, :count)
      expect(existing_entry.reload.paid).to eq(true)
      expect(subject.entry_created?).to eq(false)
      expect(subject.ipn_message.processing_result).to eq("race_entry_already_exists")
    end
  end

  context "when a paid entry already exists" do
    let!(:existing_entry) { FactoryBot.create(:race_entry, race_edition: race_edition, racer: racer, paid: true) }

    it "records the message without creating an entry or sending anything" do
      expect { subject }.not_to change(RaceEntry, :count)
      expect(subject.entry_created?).to eq(false)
      expect(subject.ipn_message.processing_result).to eq("race_entry_already_exists")
    end
  end

  context "when the same txn_id was already processed" do
    before { described_class.perform(raw_post: raw_post) }

    it "does not verify or process again" do
      expect(Paypal::VerifyIpn).to have_received(:perform).once

      expect { subject }.not_to change(Paypal::IpnMessage, :count)
      expect(subject.entry_created?).to eq(false)
      expect(subject.needs_admin_attention?).to eq(false)
      expect(Paypal::VerifyIpn).to have_received(:perform).once
    end
  end

  context "when a prior delivery failed verification with a transient error" do
    before do
      allow(Paypal::VerifyIpn).to receive(:perform).and_return("error", "verified")
      described_class.perform(raw_post: raw_post)
    end

    it "reports a retryable error, then processes the redelivery" do
      message = Paypal::IpnMessage.find_by(txn_id: "TXN00000000000001")
      expect(message.verification_status).to eq("error")

      expect { subject }.to change(RaceEntry, :count).by(1)
      expect(message.reload.verification_status).to eq("verified")
      expect(message.processing_result).to eq("race_entry_created")
    end
  end

  context "when the message is encoded in windows-1252" do
    # PayPal's default account encoding; "José" arrives as Jos%E9
    let(:ipn_fields) { super().except(:first_name).merge(charset: "windows-1252") }
    let(:raw_post) { "#{super()}&first_name=Jos%E9" }

    it "transcodes values to UTF-8 and processes normally" do
      expect { subject }.to change(RaceEntry, :count).by(1)
      expect(subject.ipn_message.first_name).to eq("José")
      expect(subject.ipn_message.processing_result).to eq("race_entry_created")
    end
  end

  context "when a value contains invalid bytes and no charset is declared" do
    let(:ipn_fields) { super().except(:last_name) }
    let(:raw_post) { "#{super()}&last_name=Sm%E9th" }

    it "scrubs the invalid bytes and processes normally" do
      expect { subject }.to change(RaceEntry, :count).by(1)
      expect(subject.ipn_message.last_name).to eq("Sm�th")
    end
  end

  context "when the message has no txn_id" do
    let(:ipn_fields) { { payment_status: "Completed" } }

    before { allow(Paypal::VerifyIpn).to receive(:perform).and_return("invalid") }

    it "stores the message anyway" do
      expect { subject }.to change(Paypal::IpnMessage, :count).by(1)
      expect(Paypal::IpnMessage.last.txn_id).to be_nil
    end
  end

  context "when the payment includes merchandise" do
    let(:ipn_fields) { super().merge(mc_gross: "70.00") }

    it "creates the entry with no merchandise size and flags for attention" do
      expect { subject }.to change(RaceEntry, :count).by(1)
      expect(RaceEntry.last.merchandise_size).to be_nil
      expect(subject.ipn_message.processing_result).to eq("created_merch_size_unknown")
      expect(subject.entry_created?).to eq(true)
      expect(subject.needs_admin_attention?).to eq(true)
    end
  end

  context "when the amount matches nothing" do
    let(:ipn_fields) { super().merge(mc_gross: "10.00") }

    it "creates no entry and flags for attention" do
      expect { subject }.not_to change(RaceEntry, :count)
      expect(subject.ipn_message.processing_result).to eq("amount_mismatch")
      expect(subject.needs_admin_attention?).to eq(true)
    end
  end

  context "when the currency is not USD" do
    let(:ipn_fields) { super().merge(mc_currency: "CAD") }

    it "creates no entry" do
      expect { subject }.not_to change(RaceEntry, :count)
      expect(subject.ipn_message.processing_result).to eq("amount_mismatch")
    end
  end

  context "when the receiver email does not match" do
    let(:ipn_fields) { super().merge(receiver_email: "attacker@example.com", business: "attacker@example.com") }

    it "creates no entry and flags for attention" do
      expect { subject }.not_to change(RaceEntry, :count)
      expect(subject.ipn_message.processing_result).to eq("receiver_mismatch")
      expect(subject.needs_admin_attention?).to eq(true)
    end
  end

  context "when the invoice is not in the expected format" do
    let(:ipn_fields) { super().merge(invoice: "RaceEntry77") }

    it "creates no entry and flags for attention" do
      expect { subject }.not_to change(RaceEntry, :count)
      expect(subject.ipn_message.processing_result).to eq("invoice_unrecognized")
      expect(subject.needs_admin_attention?).to eq(true)
    end
  end

  context "when the payment status is not Completed" do
    let(:ipn_fields) { super().merge(payment_status: "Pending") }

    it "creates no entry and needs no attention" do
      expect { subject }.not_to change(RaceEntry, :count)
      expect(subject.ipn_message.processing_result).to eq("ignored_payment_status")
      expect(subject.needs_admin_attention?).to eq(false)
    end
  end

  context "when verification returns invalid" do
    before { allow(Paypal::VerifyIpn).to receive(:perform).and_return("invalid") }

    it "stores the message and creates no entry" do
      expect { subject }.to change(Paypal::IpnMessage, :count).by(1)
      expect(RaceEntry.count).to eq(0)
      expect(subject.ipn_message.verification_status).to eq("invalid")
      expect(subject.retryable_error?).to eq(false)
    end
  end
end

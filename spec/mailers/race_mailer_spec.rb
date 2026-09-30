# frozen_string_literal: true

require "rails_helper"

RSpec.describe RaceMailer do
  let(:race_edition) { FactoryBot.create(:race_edition, :full_course, date: "2026-09-12") }
  let(:racer) { FactoryBot.create(:racer, first_name: "Jane", email: "jane@example.com") }
  let(:race_entry) { FactoryBot.create(:race_entry, race_edition: race_edition, racer: racer) }

  describe "#payment_acknowledgment" do
    subject(:mail) { described_class.payment_acknowledgment(race_entry) }

    it "is addressed to the racer" do
      expect(mail.to).to eq(["jane@example.com"])
      expect(mail.from).to be_present
    end

    it "names the course and date in the subject" do
      expect(mail.subject).to eq("Yayy! You’re entered in Full Course on September 12th")
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Hi Jane,")
      expect(mail.body.encoded).to include("confirmed for Full Course on September 12th")
      expect(mail.body.encoded).to include("Race day: September 12th")
    end

    context "when the race has no short name" do
      before { race_edition.race.update!(short_name: nil) }

      it "falls back to the race name" do
        expect(mail.subject).to include("entered in #{race_edition.race.name} on")
      end
    end
  end

  describe "#reminder" do
    subject(:mail) { described_class.reminder(race_entry, timing_label: "tomorrow") }

    it "is addressed to the racer" do
      expect(mail.to).to eq(["jane@example.com"])
    end

    it "includes the timing label in the subject" do
      expect(mail.subject).to eq("Reminder: Full Course on September 12th is tomorrow")
    end

    it "renders the body" do
      expect(mail.body.encoded).to include("Hi Jane,")
      expect(mail.body.encoded).to include("Reminder: Full Course on September 12th is tomorrow.")
    end
  end

  describe "#ipn_attention_needed" do
    subject(:mail) { described_class.ipn_attention_needed(ipn_message) }

    let(:ipn_message) do
      FactoryBot.create(
        :paypal_ipn_message,
        txn_id: "TXN12345",
        processing_result: "amount_mismatch",
        payer_email: "payer@example.com",
        first_name: "Pat",
        last_name: "Payer",
        invoice: "RaceEdition1-Racer2",
        mc_gross: 45.00,
        mc_currency: "USD"
      )
    end

    it "is addressed to the PayPal business email" do
      expect(mail.to).to eq([RambleConfig.paypal_business_email])
    end

    it "describes the result in the subject" do
      expect(mail.subject).to eq("PayPal IPN needs attention: amount mismatch")
    end

    it "renders the transaction details" do
      body = mail.body.encoded

      expect(body).to include("Result: amount_mismatch")
      expect(body).to include("Transaction ID: TXN12345")
      expect(body).to include("Amount: 45.0 USD")
      expect(body).to include("Invoice: RaceEdition1-Racer2")
      expect(body).to include("Payer: Pat Payer (payer@example.com)")
    end

    {
      "created_merch_size_unknown" => "merchandise size is not known",
      "amount_mismatch" => "does not match the entry fee",
      "invoice_unrecognized" => "does not identify a race edition and racer",
      "receiver_mismatch" => "addressed to a different receiver email"
    }.each do |result, explanation|
      context "when the result is #{result}" do
        before { ipn_message.update!(processing_result: result) }

        it "explains what to do" do
          expect(mail.body.encoded).to include(explanation)
        end
      end
    end
  end
end

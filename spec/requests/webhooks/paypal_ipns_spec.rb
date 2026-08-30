# frozen_string_literal: true

require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_have_enqueued_mail, :have_enqueued_mail

RSpec.describe "Webhooks::PaypalIpns" do
  # A method rather than a let so redelivery tests can post more than once
  def make_request
    post webhooks_paypal_ipns_path, params: raw_post, headers: { "CONTENT_TYPE" => "application/x-www-form-urlencoded" }
  end

  let(:raw_post) { URI.encode_www_form(ipn_fields) }

  let(:ipn_fields) do
    {
      txn_id: "TXN00000000000001",
      txn_type: "web_accept",
      payment_status: "Completed",
      mc_gross: mc_gross,
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

  let(:mc_gross) { "45.00" }

  let!(:race_edition) do
    FactoryBot.create(:race_edition, :full_course, date: "2027-09-18", entry_fee: 45, selling_merchandise: true, merchandise_price: 25)
  end

  let!(:racer) { FactoryBot.create(:racer, :female) }

  before { allow(Paypal::VerifyIpn).to receive(:perform).and_return(verification_outcome) }

  context "when the message verifies and the payment is complete" do
    let(:verification_outcome) { "verified" }

    it "returns 200, stores the message, and creates a paid entry" do
      expect { make_request }.to change(RaceEntry, :count).by(1)
      expect(response).to have_http_status(:ok)

      message = Paypal::IpnMessage.find_by(txn_id: "TXN00000000000001")
      expect(message.verification_status).to eq("verified")
      expect(message.processing_result).to eq("race_entry_created")
      expect(message.race_entry.paid).to eq(true)
    end

    it "sends the payment acknowledgment and schedules reminders" do
      expect { make_request }.to have_enqueued_mail(RaceMailer, :payment_acknowledgment)
        .and have_enqueued_job(ReminderJob).exactly(:twice)
    end

    it "ignores a redelivery of the same message" do
      make_request

      expect { make_request }.to not_change(RaceEntry, :count)
        .and not_change(Paypal::IpnMessage, :count)
      expect(response).to have_http_status(:ok)
    end

    it "does not send a second acknowledgment on redelivery" do
      make_request
      expect { make_request }.not_to have_enqueued_mail(RaceMailer, :payment_acknowledgment)
    end

    context "when the amount includes merchandise" do
      let(:mc_gross) { "70.00" }

      it "creates the entry without a size and alerts the race director" do
        expect { make_request }.to change(RaceEntry, :count).by(1)
          .and have_enqueued_mail(RaceMailer, :ipn_attention_needed)

        expect(RaceEntry.last.merchandise_size).to be_nil
        expect(Paypal::IpnMessage.last.processing_result).to eq("created_merch_size_unknown")
      end
    end

    context "when the amount matches nothing" do
      let(:mc_gross) { "10.00" }

      it "creates no entry and alerts the race director" do
        expect { make_request }.to not_change(RaceEntry, :count)
          .and have_enqueued_mail(RaceMailer, :ipn_attention_needed)

        expect(response).to have_http_status(:ok)
        expect(Paypal::IpnMessage.last.processing_result).to eq("amount_mismatch")
      end
    end

    context "when the payment is not complete" do
      let(:ipn_fields) { super().merge(payment_status: "Pending") }

      it "stores the message but creates no entry and sends no mail" do
        expect { make_request }.to not_change(RaceEntry, :count)
          .and not_have_enqueued_mail

        expect(response).to have_http_status(:ok)
        expect(Paypal::IpnMessage.last.processing_result).to eq("ignored_payment_status")
      end
    end
  end

  context "when the message does not verify" do
    let(:verification_outcome) { "invalid" }

    it "returns 200, stores the message, and creates nothing" do
      expect { make_request }.to not_change(RaceEntry, :count)
        .and change(Paypal::IpnMessage, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(Paypal::IpnMessage.last.verification_status).to eq("invalid")
    end
  end

  context "when verification fails transiently" do
    let(:verification_outcome) { "error" }

    it "returns 503 so PayPal redelivers, then processes the redelivery" do
      expect { make_request }.not_to change(RaceEntry, :count)
      expect(response).to have_http_status(:service_unavailable)
      expect(Paypal::IpnMessage.last.verification_status).to eq("error")

      allow(Paypal::VerifyIpn).to receive(:perform).and_return("verified")

      expect { make_request }.to change(RaceEntry, :count).by(1)
      expect(response).to have_http_status(:ok)
      expect(Paypal::IpnMessage.last.processing_result).to eq("race_entry_created")
    end
  end
end

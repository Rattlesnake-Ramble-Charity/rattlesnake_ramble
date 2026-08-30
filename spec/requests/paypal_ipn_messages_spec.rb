# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PaypalIpnMessages" do
  # The navigation layout requires a full course and a kids edition to exist
  let!(:race_edition) { FactoryBot.create(:race_edition, :full_course, date: "2026-09-12") }
  let!(:kids_edition) { FactoryBot.create(:race_edition, :kids_race, date: "2026-06-06") }

  let!(:created_message) do
    FactoryBot.create(
      :paypal_ipn_message,
      payer_email: "runner@example.com",
      verification_status: "verified",
      processing_result: "race_entry_created",
      race_entry: race_entry
    )
  end

  let!(:attention_message) do
    FactoryBot.create(
      :paypal_ipn_message,
      payer_email: "mismatch@example.com",
      verification_status: "verified",
      processing_result: "amount_mismatch"
    )
  end

  let(:race_entry) { FactoryBot.create(:race_entry, race_edition: race_edition, racer: racer) }
  let(:racer) { FactoryBot.create(:racer, :female, first_name: "Jane", last_name: "Doe") }

  describe "GET /paypal_ipn_messages" do
    let(:make_request) { get paypal_ipn_messages_path, params: params }
    let(:params) { {} }

    context "when not signed in" do
      it "redirects to the sign-in page" do
        make_request
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in FactoryBot.create(:user) }

      it "lists all messages with a link to the associated racer" do
        make_request
        expect(response.status).to eq(200)
        expect(response.body).to include("runner@example.com")
        expect(response.body).to include("mismatch@example.com")
        expect(response.body).to include("Jane Doe")
      end

      context "with the attention filter" do
        let(:params) { { filter: "attention" } }

        it "lists only messages needing attention" do
          make_request
          expect(response.body).to include("mismatch@example.com")
          expect(response.body).not_to include("runner@example.com")
        end
      end
    end
  end

  describe "GET /paypal_ipn_messages/:id" do
    let(:make_request) { get paypal_ipn_message_path(created_message) }

    context "when not signed in" do
      it "redirects to the sign-in page" do
        make_request
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in FactoryBot.create(:user) }

      it "shows the message details including the raw post body" do
        make_request
        expect(response.status).to eq(200)
        expect(response.body).to include(created_message.txn_id)
        expect(response.body).to include("runner@example.com")
        expect(response.body).to include(ERB::Util.html_escape(created_message.raw_post))
      end
    end
  end
end

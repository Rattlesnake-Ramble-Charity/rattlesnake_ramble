# frozen_string_literal: true

require "rails_helper"

RSpec.describe "RaceEntries" do
  let!(:race_edition) { FactoryBot.create(:race_edition, :full_course, date: "2026-09-12", next_male_bib_number: 100) }
  let!(:racer) { FactoryBot.create(:racer, :male) }

  describe "POST /race_entries" do
    let(:make_request) do
      post race_entries_path, params: { race_entry: { racer_id: racer.id, race_edition_id: race_edition.id } }
    end

    context "when not signed in" do
      it "redirects to the sign-in page without creating an entry" do
        expect { make_request }.not_to change(RaceEntry, :count)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in FactoryBot.create(:user) }

      it "creates a paid entry with a bib number and redirects to the racers page" do
        expect { make_request }.to change(RaceEntry, :count).by(1)

        race_entry = RaceEntry.last
        expect(race_entry.racer).to eq(racer)
        expect(race_entry.race_edition).to eq(race_edition)
        expect(race_entry.paid).to be(true)
        expect(race_entry.bib_number).to eq(100)

        expect(response).to redirect_to(racers_path)
        expect(flash[:success]).to include(racer.first_name)
      end

      it "sends the payment acknowledgment and schedules reminders" do
        expect { make_request }.to have_enqueued_mail(RaceMailer, :payment_acknowledgment)
          .and have_enqueued_job(ReminderJob).exactly(:twice)
      end

      context "when the racer is already entered" do
        let!(:existing_entry) { FactoryBot.create(:race_entry, racer: racer, race_edition: race_edition) }

        it "does not create a duplicate and shows the error" do
          expect { make_request }.not_to change(RaceEntry, :count)
          expect(response).to redirect_to(racers_path)
          expect(flash[:danger]).to include("may be added to a race_edition only once")
        end
      end
    end
  end

  describe "PATCH /race_entries/:id" do
    let!(:race_entry) { FactoryBot.create(:race_entry, racer: racer, race_edition: race_edition, paid: false) }

    before { sign_in FactoryBot.create(:user) }

    context "with a return_to param" do
      it "updates the entry and redirects to the given path" do
        patch race_entry_path(race_entry), params: { race_entry: { paid: "true" }, return_to: racers_path }

        expect(race_entry.reload.paid).to be(true)
        expect(response).to redirect_to(racers_path)
      end
    end

    context "without a return_to param" do
      it "keeps the existing redirect to the edition's entries page" do
        patch race_entry_path(race_entry), params: { race_entry: { paid: "true" } }

        expect(race_entry.reload.paid).to be(true)
        expect(response).to redirect_to(race_entries_race_edition_path(race_edition))
      end
    end
  end
end

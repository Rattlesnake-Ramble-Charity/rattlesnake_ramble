# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Racers" do
  describe "GET /racers" do
    let(:make_request) { get racers_path }

    let(:odd_years_race) { FactoryBot.create(:race, :odd_years) }
    let(:even_years_race) { FactoryBot.create(:race, :even_years) }
    let(:kids_race) { FactoryBot.create(:race, :kids_race) }

    let!(:current_full_edition) { FactoryBot.create(:race_edition, race: even_years_race, date: "2026-09-12") }
    let!(:previous_full_edition) { FactoryBot.create(:race_edition, race: odd_years_race, date: "2025-09-20") }
    let!(:current_kids_edition) { FactoryBot.create(:race_edition, race: kids_race, date: "2026-09-12") }
    let!(:previous_kids_edition) { FactoryBot.create(:race_edition, race: kids_race, date: "2026-06-01") }

    let!(:entered_racer) do
      FactoryBot.create(:racer, first_name: "Enid", last_name: "Entered", email: "enid@example.com", created_at: "2026-08-29 12:00")
    end

    let!(:entry) { FactoryBot.create(:race_entry, racer: entered_racer, race_edition: current_full_edition, paid: false) }

    let!(:orphan_racer) do
      FactoryBot.create(:racer, first_name: "Oscar", last_name: "Orphan", email: "oscar@example.com", created_at: "2026-08-29 10:00")
    end

    # same email as entered_racer: a retry-orphan
    let!(:duplicate_orphan_racer) do
      FactoryBot.create(:racer, first_name: "Enid", last_name: "Entered", email: "enid@example.com", created_at: "2026-08-28 10:00")
    end

    # after the full course cutoff (2025-09-20) but before the kids cutoff (2026-06-01)
    let!(:midseason_racer) do
      FactoryBot.create(:racer, first_name: "Mona", last_name: "Midseason", email: "mona@example.com", created_at: "2026-01-15 10:00")
    end

    let!(:old_racer) do
      FactoryBot.create(:racer, first_name: "Olaf", last_name: "Old", email: "olaf@example.com", created_at: "2024-05-05 10:00")
    end

    context "when not signed in" do
      it "redirects to the sign-in page" do
        make_request
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in FactoryBot.create(:user) }

      it "lists racers created after the last race edition, newest first" do
        make_request
        expect(response.status).to eq(200)
        expect(response.body).to include("enid@example.com")
        expect(response.body).to include("oscar@example.com")
        expect(response.body).to include("mona@example.com")
        expect(response.body).not_to include("olaf@example.com")
        expect(response.body.index("Enid Entered")).to be < response.body.index("Oscar Orphan")
        expect(response.body.index("Oscar Orphan")).to be < response.body.index("Mona Midseason")
      end

      it "shows the entry and a paid toggle for an entered racer" do
        make_request
        expect(response.body).to include(current_full_edition.name)
        expect(response.body).to include("Mark Paid")
      end

      it "shows Mark Unpaid when the entry is already paid" do
        entry.update!(paid: true)
        make_request
        expect(response.body).to include("Mark Unpaid")
      end

      it "shows add buttons only for categories whose previous edition predates the racer" do
        make_request
        # orphan_racer and duplicate_orphan_racer qualify for both courses;
        # midseason_racer only for the full course
        expect(response.body.scan("Add to Full Course").size).to eq(3)
        expect(response.body.scan("Add to Kids Course").size).to eq(2)
      end

      it "warns when another racer record with the same email is already entered" do
        make_request
        expect(response.body.scan("another racer record with this email is already entered").size).to eq(1)
      end
    end
  end
end

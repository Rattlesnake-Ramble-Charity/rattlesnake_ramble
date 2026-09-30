# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Races" do
  # The navigation layout requires a full course and a kids edition to exist
  let!(:race_edition) { FactoryBot.create(:race_edition, :full_course, date: "2026-09-12") }
  let!(:kids_edition) { FactoryBot.create(:race_edition, :kids_race, date: "2026-09-12") }
  let(:race) { race_edition.race }

  context "when not signed in" do
    it "redirects the index to the sign-in page" do
      get races_path

      expect(response).to redirect_to(new_user_session_path)
    end

    it "redirects a race page to the sign-in page" do
      get race_path(race)

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  context "when signed in" do
    before { sign_in FactoryBot.create(:user) }

    describe "GET /races" do
      it "lists the races" do
        get races_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("All Races")
        expect(response.body).to include(race.name)
        expect(response.body).to include(kids_edition.race.name)
      end
    end

    describe "GET /races/:id" do
      it "shows the race and its editions" do
        get race_path(race)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(race.name)
        expect(response.body).to include(race_edition.name)
      end

      it "permanently redirects a numeric id to the friendly slug" do
        get race_path(race.id)

        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(race_path(race.friendly_id))
      end

      it "permanently redirects an outdated slug to the current one" do
        old_slug = race.friendly_id
        race.update!(slug: "renamed-race")

        get race_path(old_slug)

        expect(response).to have_http_status(:moved_permanently)
        expect(response).to redirect_to(race_path("renamed-race"))
      end
    end

    describe "GET /races/new" do
      it "renders the form" do
        get new_race_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create a new Race")
      end
    end

    describe "GET /races/:id/edit" do
      it "renders the form" do
        get edit_race_path(race)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Edit Race")
      end
    end

    describe "POST /races" do
      it "creates a race and redirects to the index" do
        expect do
          post races_path, params: { race: { name: "Brand New Race", description: "A new race" } }
        end.to change(Race, :count).by(1)

        expect(response).to redirect_to(races_path)
        expect(flash[:success]).to include("created")
      end

      it "re-renders the form when the race is invalid" do
        expect do
          post races_path, params: { race: { name: "", description: "No name" } }
        end.not_to change(Race, :count)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Create a new Race")
      end
    end

    describe "PATCH /races/:id" do
      it "updates the race and redirects to it" do
        patch race_path(race), params: { race: { description: "Updated description" } }

        expect(race.reload.description).to eq("Updated description")
        expect(response).to redirect_to(race_path(race))
      end
    end
  end
end

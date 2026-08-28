# frozen_string_literal: true

require "rails_helper"

RSpec.describe RaceEditionsController do
  render_views

  before { FactoryBot.create(:user, email: "other@example.com", password: "password") }

  describe "#index" do
    let(:make_request) { get :index, format: :json, params: params }
    let(:params) { {} }

    before { FactoryBot.create_list(:race_edition, 2) }

    context "with no credentials" do
      it "returns 401" do
        make_request
        expect(response.status).to eq(401)
      end
    end

    context "with valid credentials" do
      let(:params) do
        {
          user: {
            email: "other@example.com",
            password: "password"
          }
        }
      end

      it "returns a successful response" do
        make_request
        expect(response.status).to eq(200)
      end

      it "returns json with all race editions" do
        make_request
        parsed_body = JSON.parse(response.body)

        expect(parsed_body).to be_a Array
        expect(parsed_body.first.keys).to match_array(%w(id date race_name))
      end
    end
  end

  describe "#show" do
    let(:make_request) { get :show, format: :json, params: params }
    let(:params) do
      {
        id: race_edition.id,
      }
    end

    let!(:race_edition) do
      FactoryBot.create(
        :race_edition,
        default_start_time_male: default_start_time_male,
        default_start_time_female: default_start_time_female,
      )
    end

    let(:default_start_time_male) { "2023-09-16 08:00:00".in_time_zone }
    let(:default_start_time_female) { "2023-09-16 08:15:00".in_time_zone }

    let!(:race_entries) do
      [
        FactoryBot.create(:race_entry, race_edition: race_edition, racer: male_racer),
        FactoryBot.create(:race_entry, race_edition: race_edition, racer: female_racer),
      ]
    end

    let(:male_racer) { FactoryBot.create(:racer, :male) }
    let(:female_racer) { FactoryBot.create(:racer, :female) }

    context "with no credentials" do
      it "returns 401" do
        make_request
        expect(response.status).to eq(401)
      end
    end

    context "with valid credentials" do
      let(:params) do
        {
          id: race_edition.id,
          user: {
            email: "other@example.com",
            password: "password",
          }
        }
      end

      let(:expected_race_edition_keys) do
        %w[created_at date default_start_time_female default_start_time_male entry_fee id race race_entries updated_at]
      end

      let(:expected_race_entry_keys) do
        %w[bib_number scheduled_start_time racer]
      end

      it "returns the race edition" do
        make_request
        parsed_body = JSON.parse(response.body)

        expect(parsed_body).to be_a(Hash)
        expect(expected_race_edition_keys).to all be_in(parsed_body.keys)
      end

      it "returns an array of race entries" do
        make_request
        parsed_body = JSON.parse(response.body)

        race_entries = parsed_body["race_entries"]
        expect(race_entries).to be_a(Array)

        male_race_entry = race_entries.first
        expect(expected_race_entry_keys).to all be_in(male_race_entry.keys)
        expect(male_race_entry["scheduled_start_time"].in_time_zone).to eq(race_edition.default_start_time_male)

        female_race_entry = race_entries.second
        expect(expected_race_entry_keys).to all be_in(female_race_entry.keys)
        expect(female_race_entry["scheduled_start_time"].in_time_zone).to eq(race_edition.default_start_time_female)
      end
    end
  end

  describe "#recruitment_emails" do
    include Devise::Test::ControllerHelpers

    let(:make_request) { get :recruitment_emails, params: { id: current_edition.friendly_id } }

    let(:odd_years_race) { FactoryBot.create(:race, :odd_years) }
    let(:even_years_race) { FactoryBot.create(:race, :even_years) }
    let(:kids_race) { FactoryBot.create(:race, :kids_race) }

    let!(:current_edition) { FactoryBot.create(:race_edition, race: odd_years_race, date: "2025-09-20") }
    let!(:previous_edition) { FactoryBot.create(:race_edition, race: even_years_race, date: "2024-09-21") }

    # The navigation layout requires a kids edition to exist; dated between the
    # two full-course editions, it also proves the previous-edition lookup
    # does not leak across race categories
    let!(:kids_edition) { FactoryBot.create(:race_edition, race: kids_race, date: "2025-06-01") }

    context "when not signed in" do
      it "redirects to the sign-in page" do
        make_request
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      let(:user) { FactoryBot.create(:user) }

      before { sign_in user }

      context "when a previous edition exists" do
        let!(:returning_entry) do
          FactoryBot.create(:race_entry, race_edition: previous_edition, racer: FactoryBot.create(:racer, email: "returning@example.com"))
        end

        it "returns a successful response listing the previous edition's racer emails" do
          make_request
          expect(response.status).to eq(200)
          expect(response.body).to include("returning@example.com")
        end

        it "excludes racers already entered in the current edition, matching by email rather than racer id" do
          FactoryBot.create(:race_entry, race_edition: previous_edition, racer: FactoryBot.create(:racer, email: "repeat@example.com"))
          FactoryBot.create(:race_entry, race_edition: current_edition, racer: FactoryBot.create(:racer, email: "repeat@example.com"))

          make_request
          expect(response.body).to include("returning@example.com")
          expect(response.body).not_to include("repeat@example.com")
        end

        it "lists a duplicated email only once" do
          FactoryBot.create(:race_entry, race_edition: previous_edition, racer: FactoryBot.create(:racer, email: "dupe@example.com"))
          FactoryBot.create(:race_entry, race_edition: previous_edition, racer: FactoryBot.create(:racer, email: "dupe@example.com"))

          make_request
          expect(response.body.scan("dupe@example.com").size).to eq(1)
        end

        it "ignores kids race editions when finding the previous full course edition" do
          FactoryBot.create(:race_entry, race_edition: kids_edition, racer: FactoryBot.create(:racer, email: "kids-parent@example.com"))

          make_request
          expect(response.body).to include("returning@example.com")
          expect(response.body).not_to include("kids-parent@example.com")
        end
      end

      context "when no previous edition exists" do
        before { previous_edition.destroy }

        it "redirects with an alert" do
          make_request
          expect(response).to redirect_to(race_editions_path)
          expect(flash[:alert]).to eq("No previous edition exists for this race.")
        end
      end
    end
  end
end

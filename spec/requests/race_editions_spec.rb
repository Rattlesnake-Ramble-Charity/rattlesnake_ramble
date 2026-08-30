# frozen_string_literal: true

require "rails_helper"

RSpec::Matchers.define_negated_matcher :not_change, :change
RSpec::Matchers.define_negated_matcher :not_have_enqueued_mail, :have_enqueued_mail

RSpec.describe "RaceEditions" do
  before { FactoryBot.create(:user, email: "other@example.com", password: "password") }

  describe "GET /race_editions.json" do
    let(:make_request) { get race_editions_path(format: :json), params: params }
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

  describe "GET /race_editions/:id.json" do
    let(:make_request) { get race_edition_path(race_edition.id, format: :json), params: params }
    let(:params) { {} }

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

  describe "POST /race_editions/:id/create_entry" do
    let(:make_request) { post create_entry_race_edition_path(race_edition), params: params }

    let!(:race_edition) do
      FactoryBot.create(:race_edition, :full_course, date: "2026-09-12", selling_merchandise: selling_merchandise, merchandise_price: 25)
    end

    let(:selling_merchandise) { false }

    # The navigation layout requires a kids edition to exist
    let!(:kids_edition) { FactoryBot.create(:race_edition, :kids_race, date: "2026-06-06") }

    let(:racer_attributes) do
      {
        first_name: "Jane",
        last_name: "Doe",
        email: "jane.doe@example.com",
        gender: "female",
        birth_date: "1980-01-01",
        city: "Boulder",
        state: "CO",
      }
    end

    context "when the edition is not selling merchandise and no race entry attributes are submitted" do
      let(:params) { { race_edition: { racers_attributes: { "0" => racer_attributes } } } }

      it "creates the racer and redirects to payment" do
        expect { make_request }.to change(Racer, :count).by(1)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("cgi-bin/webscr")
        expect(response.location).to include("notify_url=http%3A%2F%2Fwww.example.com%2Fwebhooks%2Fpaypal_ipns")
      end
    end

    context "when the edition is selling merchandise and a size is chosen" do
      let(:selling_merchandise) { true }

      let(:params) do
        {
          race_edition: {
            racers_attributes: { "0" => racer_attributes },
            race_entries_attributes: { "0" => { merchandise_size: "Men M" } },
          }
        }
      end

      it "creates the racer and redirects to payment" do
        expect { make_request }.to change(Racer, :count).by(1)
        expect(response).to have_http_status(:redirect)
        expect(response.location).to include("cgi-bin/webscr")
        expect(response.location).to include("merchandise_size%3DMen+M")
      end
    end

    context "when the racer is invalid" do
      let(:params) { { race_edition: { racers_attributes: { "0" => racer_attributes.merge(email: "") } } } }

      it "does not create a racer and re-renders the entry form" do
        expect { make_request }.not_to change(Racer, :count)
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /race_editions/:id/payment_success" do
    let(:make_request) do
      get payment_success_race_edition_path(race_edition), params: { racer_id: racer.id, merchandise_size: merchandise_size }
    end

    let(:merchandise_size) { nil }

    let!(:race_edition) do
      FactoryBot.create(:race_edition, :full_course, date: "2026-09-12", selling_merchandise: true, merchandise_price: 25)
    end

    let!(:racer) { FactoryBot.create(:racer, :female) }

    context "when no entry exists yet" do
      it "creates a paid entry and sends the acknowledgment" do
        expect { make_request }.to change(RaceEntry, :count).by(1)
          .and have_enqueued_mail(RaceMailer, :payment_acknowledgment)

        entry = RaceEntry.last
        expect(entry.racer).to eq(racer)
        expect(entry.paid).to eq(true)
        expect(response).to redirect_to(race_edition_path(race_edition))
      end
    end

    context "when the IPN listener already created the entry" do
      let!(:existing_entry) do
        FactoryBot.create(:race_entry, race_edition: race_edition, racer: racer, paid: true, merchandise_size: nil)
      end

      let(:merchandise_size) { "Men M" }

      it "backfills the merchandise size without creating a duplicate or re-sending the acknowledgment" do
        expect { make_request }.to not_change(RaceEntry, :count)
          .and not_have_enqueued_mail(RaceMailer, :payment_acknowledgment)

        expect(existing_entry.reload.merchandise_size).to eq("Men M")
        expect(existing_entry.paid).to eq(true)
        expect(response).to redirect_to(race_edition_path(race_edition))
      end
    end

    context "when the entry already has a merchandise size" do
      let!(:existing_entry) do
        FactoryBot.create(:race_entry, race_edition: race_edition, racer: racer, paid: true, merchandise_size: "Women S")
      end

      let(:merchandise_size) { "Men M" }

      it "does not overwrite the size" do
        make_request
        expect(existing_entry.reload.merchandise_size).to eq("Women S")
      end
    end
  end

  describe "GET /race_editions/:id/racer_emails" do
    let(:make_request) { get racer_emails_race_edition_path(race_edition), params: params }
    let(:params) { {} }

    let!(:race_edition) { FactoryBot.create(:race_edition, :full_course, date: "2025-09-20") }

    # The navigation layout requires a kids edition to exist
    let!(:kids_edition) { FactoryBot.create(:race_edition, :kids_race, date: "2025-06-01") }

    let!(:paid_entry) do
      FactoryBot.create(:race_entry, race_edition: race_edition, paid: true, racer: FactoryBot.create(:racer, email: "alice@example.com"))
    end

    let!(:unpaid_entry) do
      FactoryBot.create(:race_entry, race_edition: race_edition, paid: false, racer: FactoryBot.create(:racer, email: "bob@example.com"))
    end

    context "when not signed in" do
      it "redirects to the sign-in page" do
        make_request
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when signed in" do
      before { sign_in FactoryBot.create(:user) }

      it "lists emails for all entries when no filter is given" do
        make_request
        expect(response.status).to eq(200)
        expect(response.body).to include("alice@example.com")
        expect(response.body).to include("bob@example.com")
      end

      context "with a paid filter" do
        let(:params) { { filter: { paid: "true" } } }

        it "lists emails for paid entries only" do
          make_request
          expect(response.body).to include("alice@example.com")
          expect(response.body).not_to include("bob@example.com")
        end
      end

      context "with an unpaid filter" do
        let(:params) { { filter: { paid: "false" } } }

        it "lists emails for unpaid entries only" do
          make_request
          expect(response.body).to include("bob@example.com")
          expect(response.body).not_to include("alice@example.com")
        end
      end
    end
  end

  describe "GET /race_editions/:id/recruitment_emails" do
    let(:make_request) { get recruitment_emails_race_edition_path(current_edition) }

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

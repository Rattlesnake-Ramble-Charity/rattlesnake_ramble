# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Pages" do
  # The navigation layout requires a full course and a kids edition to exist
  let!(:full_course_edition) { FactoryBot.create(:race_edition, :full_course, date: edition_date) }
  let!(:kids_edition) { FactoryBot.create(:race_edition, :kids_race, date: edition_date) }
  let(:edition_date) { Date.current + 30 }

  describe "GET /" do
    it "renders the home page with the current edition details" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rattlesnake Ramble #{edition_date.year} Information")
      expect(response.body).to include(I18n.l(edition_date, format: :long_with_day))
    end

    context "when the current edition is upcoming and accepting entries" do
      it "shows the sign-up buttons" do
        get root_path

        expect(response.body).to include("Sign up for the #{edition_date.year} Edition")
        expect(response.body).to include(enter_race_edition_path(full_course_edition))
        expect(response.body).to include(enter_race_edition_path(kids_edition))
      end
    end

    context "when the current edition is full" do
      before { full_course_edition.update!(accepting_entries: false) }

      it "says the race is full but still offers the kids' race" do
        get root_path

        expect(response.body).to include("The race is full!")
        expect(response.body).not_to include(enter_race_edition_path(full_course_edition))
        expect(response.body).to include(enter_race_edition_path(kids_edition))
      end
    end

    context "when the most recent edition is in the past" do
      let(:edition_date) { Date.current - 30 }

      it "tells visitors to check back for next year's edition" do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Check back here soon for information about the #{edition_date.year + 1} Edition")
      end
    end

    context "when signed in and the full course and kids course dates differ" do
      before do
        kids_edition.update!(date: edition_date - 1)
        sign_in FactoryBot.create(:user)
      end

      it "shows the date alignment warning" do
        get root_path

        expect(response.body).to include("Race Edition dates are not aligned")
      end
    end

    context "when signed out and the dates differ" do
      before { kids_edition.update!(date: edition_date - 1) }

      it "does not show the date alignment warning" do
        get root_path

        expect(response.body).not_to include("Race Edition dates are not aligned")
      end
    end
  end

  describe "GET /home" do
    it "renders the home page" do
      get "/home"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Rattlesnake Ramble #{edition_date.year} Information")
    end
  end

  describe "GET /charity" do
    it "renders the charity page with the PayPal donation form" do
      get charity_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mission Statement")
      expect(response.body).to include('name="cmd" value="_donations"')
    end
  end

  describe "GET /thanks" do
    it "renders the donation thank-you page" do
      get thanks_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Thanks for your donation!")
    end
  end

  describe "GET /race_reports" do
    it "renders every available race report" do
      years = Dir.children(Rails.root.join("app/views/pages/race_reports")).map { |f| f.split(".").first }
      expect(years).not_to be_empty

      years.each do |year|
        get race_reports_path(year: year)

        expect(response).to have_http_status(:ok), "expected the #{year} race report to render"
        expect(response.body).to include("Race Report")
      end
    end

    it "returns 404 for a year with no report" do
      get race_reports_path(year: "1999")

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "course description pages" do
    %w[kids_course_description odd_year_course_description even_year_course_description].each do |page|
      it "renders /#{page}" do
        get "/#{page}"

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /welcome/index" do
    it "renders" do
      get "/welcome/index"

      expect(response).to have_http_status(:ok)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

# t.date "date"
# t.integer "race_id"

RSpec.describe RaceEdition, type: :model do
  describe '#initialize' do
    it 'is valid when created with a date and race_id' do
      race_edition = build_stubbed(:race_edition)
      expect(race_edition.race_id).to be_present
      expect(race_edition.date).to be_present
      expect(race_edition.entry_fee).to be_present
      expect(race_edition.default_start_time_male).to be_present
      expect(race_edition.default_start_time_female).to be_present
      expect(race_edition).to be_valid
    end

    it 'is invalid when created without a date' do
      race_edition = build_stubbed(:race_edition, date: nil)
      expect(race_edition).to be_invalid
      expect(race_edition.errors.full_messages).to include("Date can't be blank")
    end

    it 'is invalid when created without a race_id' do
      race_edition = build_stubbed(:race_edition, race_id: nil)
      expect(race_edition).to be_invalid
      expect(race_edition.errors.full_messages).to include("Race can't be blank")
    end

    it 'is invalid when created with a duplicate race on the same date' do
      existing_race_edition = create(:race_edition)
      race_edition = build(:race_edition, race: existing_race_edition.race, date: existing_race_edition.date)
      expect(race_edition).to be_invalid
      expect(race_edition.errors.full_messages).to include('Race has already been taken')
    end

    it 'is invalid with a non-positive next male bib number' do
      race_edition = build_stubbed(:race_edition, next_male_bib_number: 0)
      expect(race_edition).to be_invalid
      expect(race_edition.errors.full_messages).to include('Next male bib number must be greater than 0')
    end
  end

  describe '#default_start_time_female_local= and #default_start_time_male_local=' do
    subject do
      build_stubbed(:race_edition,
                    date: date,
                    default_start_time_female_local: default_start_time_female_local,
                    default_start_time_male_local: default_start_time_male_local)
    end
    let(:date) { '2020-09-12'.to_date }

    context 'when given nil' do
      let(:default_start_time_female_local) { nil }
      let(:default_start_time_male_local) { nil }
      it 'sets the underlying attributes to nil' do
        expect(subject.default_start_time_female).to be_nil
        expect(subject.default_start_time_male).to be_nil
      end
    end

    context 'when given a time string without a time zone' do
      let(:default_start_time_female_local) { '2020-09-12 7:45:00' }
      let(:default_start_time_male_local) { '2020-09-12 7:30:00' }
      it 'sets the underlying attributes using home time zone' do
        expect(subject.default_start_time_female).to eq('2020-09-12 07:45:00-0600'.to_datetime)
        expect(subject.default_start_time_male).to eq('2020-09-12 07:30:00-0600'.to_datetime)
      end
    end

    context 'when given a military time string' do
      let(:default_start_time_female_local) { '7:45:00' }
      let(:default_start_time_male_local) { '7:30:00' }
      it 'sets the underlying attributes using date and home time zone' do
        expect(subject.default_start_time_female).to eq('2020-09-12 07:45:00-0600'.to_datetime)
        expect(subject.default_start_time_male).to eq('2020-09-12 07:30:00-0600'.to_datetime)
      end
    end
  end

  describe '#kids_race?' do
    it 'returns true for kids race editions' do
      expect(build_stubbed(:race_edition, :kids_race)).to be_kids_race
    end

    it 'returns false for full course editions' do
      expect(build_stubbed(:race_edition, :full_course)).not_to be_kids_race
    end
  end

  describe '#previous_edition' do
    subject(:edition) { create(:race_edition, race: odd_years_race, date: '2025-09-20') }

    let(:odd_years_race) { create(:race, :odd_years) }
    let(:even_years_race) { create(:race, :even_years) }
    let(:kids_race) { create(:race, :kids_race) }

    it 'returns the most recent earlier full course edition, crossing race records' do
      create(:race_edition, race: odd_years_race, date: '2023-09-16')
      most_recent_previous = create(:race_edition, race: even_years_race, date: '2024-09-21')

      expect(edition.previous_edition).to eq(most_recent_previous)
    end

    it 'ignores kids race editions and later editions' do
      create(:race_edition, race: kids_race, date: '2025-06-01')
      create(:race_edition, race: even_years_race, date: '2026-09-19')

      expect(edition.previous_edition).to be_nil
    end

    it 'returns nil when no earlier edition exists' do
      expect(edition.previous_edition).to be_nil
    end

    context 'for a kids race edition' do
      subject(:edition) { create(:race_edition, race: kids_race, date: '2025-09-20') }

      it 'returns the most recent earlier kids edition, ignoring full course editions' do
        create(:race_edition, race: even_years_race, date: '2025-06-07')
        previous_kids_edition = create(:race_edition, race: kids_race, date: '2024-09-21')

        expect(edition.previous_edition).to eq(previous_kids_edition)
      end
    end
  end
end

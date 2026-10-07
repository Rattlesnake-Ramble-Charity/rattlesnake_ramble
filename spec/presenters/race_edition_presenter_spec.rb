# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RaceEditionPresenter do
  subject { RaceEditionPresenter.new(race_edition) }
  let(:race_edition) { build_stubbed(:race_edition, race: race) }
  let(:race) { build_stubbed(:race) }

  describe 'missing methods' do
    it 'passes missing methods through to the race_edition' do
      expect(subject.date).to eq(race_edition.date)
      expect(subject.name).to eq(race_edition.name)
    end
  end

  describe '#categories' do
    context 'when the race does not include "kids" in the name' do
      let(:race) { build_stubbed(:race, name: '2019 Ramble') }

      it 'uses the adult categories' do
        expect(subject.category_size_map.size).to eq(12)
        expect(subject.category_size_map.map(&:first)).to eq(['Under 20 Men', 'Under 20 Women', '20 to 29 Men', '20 to 29 Women', '30 to 39 Men', '30 to 39 Women', '40 to 49 Men', '40 to 49 Women', '50 to 59 Men', '50 to 59 Women', '60+ Men', '60+ Women'])
      end
    end

    context 'when the race includes "kids" in the name' do
      let(:race) { build_stubbed(:race, name: '2019 Ramble Kids', short_name: 'Kids Race') }

      it 'uses the kids categories' do
        expect(subject.category_size_map.size).to eq(2)
        expect(subject.category_size_map.map(&:first)).to eq(['Boys', 'Girls'])
      end
    end
  end

  describe '#sorted_race_entries' do
    subject { RaceEditionPresenter.new(race_edition, params) }
    let(:race_edition) { FactoryBot.create(:race_edition, :full_course, date: '2026-09-12') }
    let(:params) { {} }

    let!(:young) { FactoryBot.create(:race_entry, race_edition: race_edition, bib_number: 3, racer: FactoryBot.create(:racer, last_name: 'Young', birth_date: '2005-01-01')) }
    # Racer capitalizes last_name on save; set a lowercase one directly so the
    # case-insensitive ordering is actually exercised.
    let!(:middle) do
      FactoryBot.create(:race_entry, race_edition: race_edition, bib_number: 1, racer: FactoryBot.create(:racer, last_name: 'Abbott', birth_date: '1985-01-01'))
        .tap { |entry| entry.racer.update_column(:last_name, 'abbott') }
    end
    let!(:old) { FactoryBot.create(:race_entry, race_edition: race_edition, bib_number: 2, racer: FactoryBot.create(:racer, last_name: 'Baker', birth_date: '1965-01-01')) }

    def ordered_last_names
      subject.sorted_race_entries.map { |entry| entry.racer.last_name }
    end

    it 'sorts by last name, case-insensitively, when no sort is given' do
      expect(ordered_last_names).to eq(%w[abbott Baker Young])
    end

    context 'with an allowed sort key' do
      let(:params) { { sort: 'age' } }

      it 'applies that order' do
        expect(ordered_last_names).to eq(%w[Young abbott Baker])
      end
    end

    context 'with the bib key' do
      let(:params) { { sort: 'bib' } }

      it 'orders by bib number' do
        expect(subject.sorted_race_entries.map(&:bib_number)).to eq([1, 2, 3])
      end
    end

    context 'with an unknown sort key' do
      let(:params) { { sort: 'nonsense' } }

      it 'falls back to the default order' do
        expect(ordered_last_names).to eq(%w[abbott Baker Young])
      end
    end

    context 'with raw SQL in the sort param' do
      let(:params) { { sort: 'racers.birth_date+desc' } }

      it 'ignores it rather than raising' do
        expect { subject.sorted_race_entries }.not_to raise_error
        expect(ordered_last_names).to eq(%w[abbott Baker Young])
      end
    end
  end

  describe '#sort_key' do
    it 'returns the requested key when allowed' do
      expect(RaceEditionPresenter.new(race_edition, sort: 'paid').sort_key).to eq('paid')
    end

    it 'returns the default for blank or unknown keys' do
      expect(RaceEditionPresenter.new(race_edition, {}).sort_key).to eq('racer')
      expect(RaceEditionPresenter.new(race_edition, sort: 'DROP TABLE').sort_key).to eq('racer')
    end
  end
end

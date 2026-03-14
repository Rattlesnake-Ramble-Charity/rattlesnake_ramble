class RaceEdition < ActiveRecord::Base
  extend FriendlyId
  include TimeZonable

  KIDS_RACE_NAME = "Rattlesnake Ramble Kids Race".freeze
  MERCHANDISE_SIZES = ["Women S", "Women M", "Women L", "Men S", "Men M", "Men L", "Men XL"]

  belongs_to :race
  has_many :race_entries, dependent: :destroy
  has_many :racers, through: :race_entries

  zonable_attributes :default_start_time_female, :default_start_time_male

  accepts_nested_attributes_for :racers
  accepts_nested_attributes_for :race_entries
  friendly_id :name, use: [:slugged, :history]

  validates :race_id, presence: true
  validates :date, presence: true
  validates :entry_fee, presence: true
  validates :default_start_time_male, presence: true
  validates :default_start_time_female, presence: true
  validates :next_male_bib_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :next_female_bib_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :next_kids_bib_number, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates_uniqueness_of :race_id, scope: :date

  scope :kids_race, -> { joins(:race).where(races: {name: KIDS_RACE_NAME}) }
  scope :full_course, -> { joins(:race).where.not(races: {name: KIDS_RACE_NAME}) }

  def name
    "#{race&.short_name} on #{date}"
  end

  def home_time_zone
    ::RambleConfig.home_time_zone
  end

  def kids_race?
    race&.name == KIDS_RACE_NAME
  end

  def assign_next_bib_number_for!(racer)
    column = bib_number_column_for(racer)
    next_bib_number = public_send(column)
    return if next_bib_number.blank?

    while race_entries.exists?(bib_number: next_bib_number)
      next_bib_number += 1
    end

    update_column(column, next_bib_number + 1)
    next_bib_number
  end

  private

  def bib_number_column_for(racer)
    return :next_kids_bib_number if kids_race?

    racer.male? ? :next_male_bib_number : :next_female_bib_number
  end

  def should_generate_new_friendly_id?
    true
  end
end

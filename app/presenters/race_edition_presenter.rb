# frozen_string_literal: true

class RaceEditionPresenter < SimpleDelegator
  ADULT_CATEGORY_KEYS = %i[men_under_20 women_under_20 men_20s women_20s men_30s women_30s men_40s women_40s men_50s women_50s men_60_plus women_60_plus]
  KIDS_CATEGORY_KEYS = %i[boys girls]

  # Allowed values for the ?sort= param on entry listings, mapped to the order
  # clause each one means. Anything else falls back to DEFAULT_SORT_KEY, so a
  # request parameter never reaches ORDER BY as raw SQL.
  SORT_ORDERS = {
    "racer" => "LOWER(racers.last_name), LOWER(racers.first_name)",
    "email" => "racers.email",
    "gender" => "racers.gender, racers.birth_date DESC",
    "age" => "racers.birth_date DESC",
    "bib" => "race_entries.bib_number, racers.last_name",
    "start_time" => "race_entries.scheduled_start_time, race_entries.bib_number",
    "paid" => "race_entries.paid, race_entries.bib_number, racers.last_name",
    "time" => "race_entries.time",
    "merchandise_size" => "race_entries.merchandise_size"
  }.freeze
  DEFAULT_SORT_KEY = "racer"

  def initialize(race_edition, params = {})
    super(race_edition)
    @params = params
  end

  def category_size_map
    race_entries.each { |entry| assign_category(entry) }
    grouped_race_entries = race_entries.group_by(&:category_name)
    categories.map { |category| [category.name, grouped_race_entries[category.name]&.size || 0] }
  end

  def edition_count
    return nil unless year.present?

    year - 2004
  end

  def short_description
    case race&.name
      when "Rattlesnake Ramble Trail Race - Odd Years"
        "Fowler Trail First"
      when "Rattlesnake Ramble Trail Race - Even Years"
        "Eldorado Trail First"
      when "Rattlesnake Ramble Kids Race"
        "Kids Race"
      else
        nil
    end
  end

  def sorted_race_entries
    race_entries.includes(:racer).joins(:racer)
                .order(Arel.sql(SORT_ORDERS.fetch(sort_key)))
                .map { |re| RaceEntryPresenter.new(re) }
  end

  # The effective sort key: the requested one if it is allowed, else the default.
  def sort_key
    requested = params[:sort].to_s
    SORT_ORDERS.key?(requested) ? requested : DEFAULT_SORT_KEY
  end

  def year
    date&.year
  end

  def description_path
    if date&.year.even?
      'even_year_course_description'
    else
      'odd_year_course_description'
    end
  end

  private

  attr_reader :params

  def categories
    category_keys.map { |key| Results::Categories.find(key) }
  end

  def category_keys
    name.downcase.include?('kids') ? KIDS_CATEGORY_KEYS : ADULT_CATEGORY_KEYS
  end

  def assign_category(race_entry)
    racer = race_entry.racer
    category = categories.find do |category|
      category.age_range.include?(racer.current_age) && category.genders.include?(racer.gender)
    end
    race_entry.category_name = category.name
  end
end

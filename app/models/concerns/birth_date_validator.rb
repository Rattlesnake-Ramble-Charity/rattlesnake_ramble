# frozen_string_literal: true

class BirthDateValidator < ActiveModel::Validator
  MINIMUM_AGE_YEARS = 1

  def validate(record)
    birth_date = record.birth_date
    return if birth_date.blank?

    today = Date.today

    if birth_date < '1900-01-01'.to_date
      record.errors.add(:birth_date, "can't be before 1900")
    elsif birth_date > today
      record.errors.add(:birth_date, "can't be in the future")
    elsif birth_date > today - MINIMUM_AGE_YEARS.years
      record.errors.add(:birth_date, "is too recent (the racer would be less than #{MINIMUM_AGE_YEARS} year old); please check the year")
    end
  end
end

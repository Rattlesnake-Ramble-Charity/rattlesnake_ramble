FactoryBot.define do
  factory :race_edition do
    date { FFaker::Time.date }
    race
    entry_fee { rand(10..1000) }
    default_start_time_male { date }
    default_start_time_female { date }

    trait :full_course do
      association :race, :odd_years
    end

    trait :kids_race do
      association :race, :kids_race
    end
  end
end

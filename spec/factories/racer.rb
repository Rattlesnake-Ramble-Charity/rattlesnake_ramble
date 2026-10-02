FactoryBot.define do
  factory :racer do
    first_name { FFaker::Name.first_name_male }
    last_name { FFaker::Name.last_name }
    gender { Racer.genders.keys.sample }
    email { FFaker::Internet.disposable_email }
    birth_date { Date.current - rand(10..80).years }

    trait :male do
      gender { :male }
    end

    trait :female do
      gender { :female }
    end
  end
end

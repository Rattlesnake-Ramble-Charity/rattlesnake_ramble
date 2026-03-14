FactoryBot.define do
  factory :race do
    name { FFaker::Product.product_name }

    trait :odd_years do
      name { "Rattlesnake Ramble Trail Race - Odd Years" }
      short_name { "Full Course" }
    end

    trait :even_years do
      name { "Rattlesnake Ramble Trail Race - Even Years" }
      short_name { "Full Course" }
    end

    trait :kids_race do
      name { "Rattlesnake Ramble Kids Race" }
      short_name { "Kids Course" }
    end
  end
end

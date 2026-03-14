FactoryBot.define do
  factory :race do
    name { FFaker::Product.product_name }

    trait :odd_years do
      name { "Rattlesnake Ramble Trail Race - Odd Years" }
      short_name { "Full Course" }
      initialize_with do
        Race.find_or_initialize_by(name: name).tap do |race|
          race.short_name = short_name
        end
      end
    end

    trait :even_years do
      name { "Rattlesnake Ramble Trail Race - Even Years" }
      short_name { "Full Course" }
      initialize_with do
        Race.find_or_initialize_by(name: name).tap do |race|
          race.short_name = short_name
        end
      end
    end

    trait :kids_race do
      name { "Rattlesnake Ramble Kids Race" }
      short_name { "Kids Course" }
      initialize_with do
        Race.find_or_initialize_by(name: name).tap do |race|
          race.short_name = short_name
        end
      end
    end
  end
end

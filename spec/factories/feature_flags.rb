FactoryBot.define do
  factory :feature_flag do
    sequence(:name) { |n| "test_feature_#{n}" }
    description { "Test feature flag description" }
    enabled { false }

    trait :enabled do
      enabled { true }
    end

    trait :disabled do
      enabled { false }
    end
  end
end

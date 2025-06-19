FactoryBot.define do
  factory :feature_flag_assignment do
    feature_flag
    association :assignable, factory: :user

    trait :for_user do
      association :assignable, factory: :user
    end

    trait :for_role do
      association :assignable, factory: :role
    end
  end
end

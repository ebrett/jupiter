FactoryBot.define do
  factory :session do
    user
    ip_address { "127.0.0.1" }
    user_agent { "Test User Agent" }
    remember_me { false }

    trait :with_remember_me do
      remember_me { true }
    end

    trait :expired do
      created_at { 1.year.ago }
    end
  end
end

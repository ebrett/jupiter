FactoryBot.define do
  factory :nationbuilder_token do
    association :user
    access_token { "access_token_#{SecureRandom.hex(16)}" }
    refresh_token { "refresh_token_#{SecureRandom.hex(16)}" }
    expires_at { 1.hour.from_now }
    scope { "people:read sites:read" }
    raw_response do
      {
        "access_token" => access_token,
        "refresh_token" => refresh_token,
        "expires_in" => 3600,
        "scope" => scope,
        "token_type" => "Bearer"
      }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :expiring_soon do
      expires_at { 3.minutes.from_now }
    end

    trait :fresh do
      expires_at { 1.hour.from_now }
    end
  end
end
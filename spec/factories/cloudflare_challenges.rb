FactoryBot.define do
  factory :cloudflare_challenge do
    challenge_id { SecureRandom.uuid }
    challenge_type { 'turnstile' }
    challenge_data { { site_key: 'test-site-key', challenge_url: 'https://example.com/challenge' } }
    oauth_state { SecureRandom.hex(16) }
    original_params { { code: 'oauth-code-123', state: oauth_state } }
    session_id { SecureRandom.hex(32) }
    expires_at { 15.minutes.from_now }
    user { nil }

    trait :with_user do
      user { association :user }
    end

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :browser_challenge do
      challenge_type { 'browser_challenge' }
    end

    trait :rate_limit do
      challenge_type { 'rate_limit' }
    end
  end
end

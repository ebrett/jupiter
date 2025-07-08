require 'rails_helper'

RSpec.describe CloudflareChallenge, type: :model do
  describe 'validations' do
    it 'validates presence of challenge_id' do
      challenge = described_class.new
      expect(challenge).not_to be_valid
      expect(challenge.errors[:challenge_id]).to include("can't be blank")
    end

    it 'validates uniqueness of challenge_id' do
      create(:cloudflare_challenge, challenge_id: 'unique-id')
      duplicate = build(:cloudflare_challenge, challenge_id: 'unique-id')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:challenge_id]).to include('has already been taken')
    end

    it 'validates presence of oauth_state' do
      challenge = described_class.new
      expect(challenge).not_to be_valid
      expect(challenge.errors[:oauth_state]).to include("can't be blank")
    end

    it 'validates challenge_type inclusion' do
      valid_types = %w[turnstile browser_challenge rate_limit]

      valid_types.each do |type|
        challenge = build(:cloudflare_challenge, challenge_type: type)
        expect(challenge).to be_valid
      end

      invalid_challenge = build(:cloudflare_challenge, challenge_type: 'invalid_type')
      expect(invalid_challenge).not_to be_valid
      expect(invalid_challenge.errors[:challenge_type]).to include('is not included in the list')
    end
  end

  describe 'associations' do
    it 'belongs to user optionally' do
      challenge = build(:cloudflare_challenge, user: nil)
      expect(challenge).to be_valid

      user = create(:user)
      challenge_with_user = build(:cloudflare_challenge, user: user)
      expect(challenge_with_user).to be_valid
    end
  end

  describe 'scopes' do
    describe '.active' do
      it 'returns challenges that have not expired' do
        active_challenge = create(:cloudflare_challenge, expires_at: 1.hour.from_now)
        expired_challenge = create(:cloudflare_challenge, expires_at: 1.hour.ago)

        expect(described_class.active).to include(active_challenge)
        expect(described_class.active).not_to include(expired_challenge)
      end
    end

    describe '.for_session' do
      it 'returns challenges for specific session' do
        session_id = 'test-session-123'
        matching_challenge = create(:cloudflare_challenge, session_id: session_id)
        other_challenge = create(:cloudflare_challenge, session_id: 'other-session')

        result = described_class.for_session(session_id)
        expect(result).to include(matching_challenge)
        expect(result).not_to include(other_challenge)
      end
    end
  end

  describe 'instance methods' do
    describe '#expired?' do
      it 'returns true when expires_at is in the past' do
        challenge = build(:cloudflare_challenge, expires_at: 1.hour.ago)
        expect(challenge.expired?).to be true
      end

      it 'returns false when expires_at is in the future' do
        challenge = build(:cloudflare_challenge, expires_at: 1.hour.from_now)
        expect(challenge.expired?).to be false
      end

      it 'returns false when expires_at is exactly now' do
        freeze_time = Time.current
        travel_to freeze_time do
          challenge = build(:cloudflare_challenge, expires_at: freeze_time)
          expect(challenge.expired?).to be false
        end
      end
    end

    describe '#challenge_url' do
      it 'returns the correct challenge URL' do
        challenge = build(:cloudflare_challenge, challenge_id: 'test-id-123')
        expected_url = Rails.application.routes.url_helpers.cloudflare_challenge_path('test-id-123')
        expect(challenge.challenge_url).to eq(expected_url)
      end
    end

    describe '#manual_verification?' do
      it 'returns true for browser_challenge type' do
        challenge = build(:cloudflare_challenge, challenge_type: 'browser_challenge')
        expect(challenge.manual_verification?).to be true
      end

      it 'returns false for turnstile type' do
        challenge = build(:cloudflare_challenge, challenge_type: 'turnstile')
        expect(challenge.manual_verification?).to be false
      end

      it 'returns false for rate_limit type' do
        challenge = build(:cloudflare_challenge, challenge_type: 'rate_limit')
        expect(challenge.manual_verification?).to be false
      end
    end

    describe '#verification_completed?' do
      context 'with manual verification challenge' do
        let(:challenge) { create(:cloudflare_challenge, challenge_type: 'browser_challenge') }

        it 'returns false when challenge has not been touched' do
          expect(challenge.verification_completed?).to be false
        end

        it 'returns true when challenge has been touched' do
          challenge.touch
          expect(challenge.verification_completed?).to be true
        end
      end

      context 'with non-manual verification challenge' do
        let(:challenge) { create(:cloudflare_challenge, challenge_type: 'turnstile') }

        it 'returns false even when touched' do
          challenge.touch
          expect(challenge.verification_completed?).to be false
        end
      end
    end
  end

  describe 'data integrity' do
    it 'stores challenge_data as JSON' do
      data = { 'site_key' => 'test-key', 'turnstile_present' => true }
      challenge = create(:cloudflare_challenge, challenge_data: data)
      challenge.reload

      expect(challenge.challenge_data).to eq(data)
      expect(challenge.challenge_data['site_key']).to eq('test-key')
    end

    it 'stores original_params as JSON' do
      params = { 'code' => 'oauth123', 'state' => 'state456', 'extra' => 'value' }
      challenge = create(:cloudflare_challenge, original_params: params)
      challenge.reload

      expect(challenge.original_params).to eq(params)
      expect(challenge.original_params['code']).to eq('oauth123')
    end

    it 'handles empty JSON fields gracefully' do
      challenge = create(:cloudflare_challenge, challenge_data: {}, original_params: {})
      challenge.reload

      expect(challenge.challenge_data).to eq({})
      expect(challenge.original_params).to eq({})
    end
  end

  describe 'edge cases' do
    it 'handles very long challenge_id' do
      long_id = 'a' * 255  # Test boundary
      challenge = build(:cloudflare_challenge, challenge_id: long_id)
      expect(challenge).to be_valid
    end

    it 'handles unicode characters in oauth_state' do
      unicode_state = 'test_state_ü∑∫∆'
      challenge = build(:cloudflare_challenge, oauth_state: unicode_state)
      expect(challenge).to be_valid
      expect(challenge.oauth_state).to eq(unicode_state)
    end

    it 'enforces required fields even with valid associations' do
      user = create(:user)
      challenge = build(:cloudflare_challenge,
                       user: user,
                       challenge_id: nil,
                       oauth_state: nil)
      expect(challenge).not_to be_valid
      expect(challenge.errors[:challenge_id]).to include("can't be blank")
      expect(challenge.errors[:oauth_state]).to include("can't be blank")
    end
  end
end

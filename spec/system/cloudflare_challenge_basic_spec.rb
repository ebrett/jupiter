require 'rails_helper'

RSpec.describe 'Cloudflare Challenge Basic System Tests', type: :system do
  before do
    driven_by(:rack_test)

    # Enable cloudflare challenge handling feature flag
    @cloudflare_flag = FeatureFlag.find_or_create_by!(name: 'cloudflare_challenge_handling') do |flag|
      flag.description = 'Test flag for Cloudflare challenge handling'
      flag.enabled = true
    end
  end

  describe 'Feature Flag Behavior' do
    context 'when cloudflare_challenge_handling is enabled' do
      it 'allows access to challenge pages' do
        challenge = create(:cloudflare_challenge, session_id: 'test_session')

        # Mock session to match challenge
        controller_double = instance_double(CloudflareChallengesController)
        allow(controller_double).to receive(:session).and_return(
          double('session', id: 'test_session')
        )
        allow(CloudflareChallengesController).to receive(:new).and_return(controller_double)

        visit cloudflare_challenge_path(challenge.challenge_id)

        expect(page).to have_content('Verification Required')
        expect(page).to have_content('Additional verification required')
      end
    end

    context 'when cloudflare_challenge_handling is disabled' do
      before do
        @cloudflare_flag.update!(enabled: false)
      end

      it 'blocks access to challenge pages' do
        challenge = create(:cloudflare_challenge)
        visit cloudflare_challenge_path(challenge.challenge_id)

        expect(page).to have_current_path(sign_in_path)
        expect(page).to have_content('Challenge handling is currently unavailable')
      end
    end
  end

  describe 'Error Handling' do
    context 'when challenge not found' do
      it 'redirects to sign-in with error' do
        visit cloudflare_challenge_path('non-existent-challenge-id')

        expect(page).to have_current_path(sign_in_path)
        expect(page).to have_content('Challenge not found')
      end
    end
  end

  describe 'Navigation' do
    let(:challenge) do
      create(:cloudflare_challenge,
             challenge_type: 'turnstile',
             session_id: 'test_session')
    end

    before do
      controller_double = instance_double(CloudflareChallengesController)
      allow(controller_double).to receive(:session).and_return(
        double('session', id: 'test_session')
      )
      allow(CloudflareChallengesController).to receive(:new).and_return(controller_double)
    end

    it 'provides alternative sign-in option' do
      visit cloudflare_challenge_path(challenge.challenge_id)

      expect(page).to have_link('Try alternative sign-in', href: sign_in_path)
      click_link 'Try alternative sign-in'

      expect(page).to have_current_path(sign_in_path)
    end
  end
end

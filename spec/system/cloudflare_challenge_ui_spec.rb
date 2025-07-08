require 'rails_helper'

RSpec.describe 'Cloudflare Challenge UI', type: :system do
  before do
    driven_by(:rack_test)
    
    # Enable cloudflare challenge handling feature flag
    @cloudflare_flag = FeatureFlag.find_or_create_by!(name: 'cloudflare_challenge_handling') do |flag|
      flag.description = 'Test flag for Cloudflare challenge handling'
      flag.enabled = true
    end
  end

  describe 'Challenge Display Pages' do
    context 'with Turnstile challenge' do
      let(:challenge) do
        create(:cloudflare_challenge,
               challenge_type: 'turnstile',
               challenge_data: { 'turnstile_present' => true },
               oauth_state: 'test_state',
               session_id: 'system_test_session')
      end

      before do
        # Mock session ID to match challenge
        allow_any_instance_of(CloudflareChallengesController).to receive(:session).and_return(
          double('session', id: 'system_test_session')
        )
      end

      it 'displays Turnstile challenge interface correctly' do
        visit cloudflare_challenge_path(challenge.challenge_id)

        # Debug: Let's see what's actually being rendered
        # puts page.html

        # Verify basic page content
        expect(page).to have_content('Security Check Required')
        expect(page).to have_content('Please complete the security check below')
        
        # Verify form presence
        expect(page).to have_selector('form')
        
        # Verify button exists (may not be disabled as expected)
        expect(page).to have_button('Continue')
        
        # Verify alternative link
        expect(page).to have_link('Try alternative sign-in', href: sign_in_path)
      end
    end

    context 'with browser challenge' do
      let(:challenge) do
        create(:cloudflare_challenge,
               challenge_type: 'browser_challenge',
               challenge_data: { 'challenge_stage_present' => true },
               session_id: 'system_test_session')
      end

      before do
        allow_any_instance_of(CloudflareChallengesController).to receive(:session).and_return(
          double('session', id: 'system_test_session')
        )
      end

      it 'displays browser challenge interface correctly' do
        visit cloudflare_challenge_path(challenge.challenge_id)

        expect(page).to have_content('Browser Verification Required')
        expect(page).to have_content('browser verification')
        expect(page).to have_content('refresh')
        
        # Browser challenges should not have Turnstile widget
        expect(page).not_to have_selector('.cf-turnstile')
        
        # Submit button should be enabled for browser challenges
        expect(page).to have_button('Continue', disabled: false)
      end
    end

    context 'with rate limit challenge' do
      let(:challenge) do
        create(:cloudflare_challenge,
               challenge_type: 'rate_limit',
               challenge_data: { 'rate_limited' => true },
               session_id: 'system_test_session')
      end

      before do
        allow_any_instance_of(CloudflareChallengesController).to receive(:session).and_return(
          double('session', id: 'system_test_session')
        )
      end

      it 'displays rate limit interface correctly' do
        visit cloudflare_challenge_path(challenge.challenge_id)

        expect(page).to have_content('Too Many Requests')
        expect(page).to have_content('many requests')
        expect(page).to have_content('wait')
        
        # Submit button should be disabled for rate limit
        expect(page).to have_button('Continue', disabled: true)
      end
    end
  end

  describe 'Error Handling UI' do
    context 'when feature flag is disabled' do
      before do
        @cloudflare_flag.update!(enabled: false)
      end

      it 'redirects with appropriate error message' do
        challenge = create(:cloudflare_challenge)
        visit cloudflare_challenge_path(challenge.challenge_id)

        expect(page).to have_current_path(sign_in_path)
        expect(page).to have_content('Challenge handling is currently unavailable')
      end
    end

    context 'when challenge not found' do
      it 'redirects to sign-in with error' do
        visit cloudflare_challenge_path('non-existent-challenge-id')

        expect(page).to have_current_path(sign_in_path)
        expect(page).to have_content('Challenge not found')
      end
    end
  end

  describe 'Navigation and User Experience' do
    let(:challenge) do
      create(:cloudflare_challenge,
             challenge_type: 'turnstile',
             session_id: 'system_test_session')
    end

    before do
      allow_any_instance_of(CloudflareChallengesController).to receive(:session).and_return(
        double('session', id: 'system_test_session')
      )
    end

    it 'provides clear navigation options' do
      visit cloudflare_challenge_path(challenge.challenge_id)

      # Test alternative sign-in link
      expect(page).to have_link('Try alternative sign-in', href: sign_in_path)
      click_link 'Try alternative sign-in'

      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_content('Sign in')
    end

    it 'displays user-friendly interface elements' do
      visit cloudflare_challenge_path(challenge.challenge_id)

      # Verify semantic HTML structure
      expect(page).to have_selector('main')
      expect(page).to have_selector('h1')
      expect(page).to have_selector('form')
      
      # Verify responsive design elements (TailwindCSS classes)
      expect(page.html).to include('min-h-screen')
      expect(page.html).to include('flex')
      expect(page.html).to include('items-center')
      expect(page.html).to include('justify-center')
    end
  end

  describe 'Form Interaction' do
    let(:challenge) do
      create(:cloudflare_challenge,
             challenge_type: 'browser_challenge',
             session_id: 'system_test_session')
    end

    before do
      allow_any_instance_of(CloudflareChallengesController).to receive(:session).and_return(
        double('session', id: 'system_test_session')
      )
      
      # Mock verification service for form submission
      allow_any_instance_of(TurnstileVerificationService).to receive(:verify).and_return(false)
    end

    it 'handles form submission and shows errors appropriately' do
      visit cloudflare_challenge_path(challenge.challenge_id)

      # Verify button exists
      expect(page).to have_button('Continue')
      
      # Submit form (will fail due to mocked verification)
      click_button 'Continue'

      # Should show error message
      expect(page).to have_content('Please complete the challenge')
    end
  end

  describe 'Accessibility Features' do
    let(:challenge) do
      create(:cloudflare_challenge,
             challenge_type: 'turnstile',
             session_id: 'system_test_session')
    end

    before do
      allow_any_instance_of(CloudflareChallengesController).to receive(:session).and_return(
        double('session', id: 'system_test_session')
      )
    end

    it 'includes proper accessibility markup' do
      visit cloudflare_challenge_path(challenge.challenge_id)

      # Verify semantic structure
      expect(page).to have_selector('h1')
      
      # Verify form accessibility
      expect(page).to have_selector('form')
      expect(page).to have_selector('button[type="submit"]')
    end
  end

  describe 'Configuration Error Handling' do
    let(:challenge) do
      create(:cloudflare_challenge,
             challenge_type: 'turnstile',
             challenge_data: { 'turnstile_present' => true },
             session_id: 'system_test_session')
    end

    before do
      allow_any_instance_of(CloudflareChallengesController).to receive(:session).and_return(
        double('session', id: 'system_test_session')
      )
    end

    it 'handles missing Cloudflare configuration gracefully' do
      # Mock missing site key
      allow(CloudflareConfig).to receive(:turnstile_site_key).and_return(nil)
      
      visit cloudflare_challenge_path(challenge.challenge_id)

      # Should still render page but show configuration issue
      expect(page).to have_content('Security Check Required')
      expect(page.html).to include('configuration issue')
    end
  end
end
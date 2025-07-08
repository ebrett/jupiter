require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'Cloudflare Challenge System Flow', type: :system do
  include ActiveJob::TestHelper
  include WebMock::API

  before do
    driven_by(:rack_test)
    
    # Set up test environment
    @original_slug = ENV['NATIONBUILDER_NATION_SLUG']
    ENV['NATIONBUILDER_NATION_SLUG'] = 'testnation'
    @original_client_id = ENV['NATIONBUILDER_CLIENT_ID']
    ENV['NATIONBUILDER_CLIENT_ID'] = 'dummy_id'
    @original_client_secret = ENV['NATIONBUILDER_CLIENT_SECRET']
    ENV['NATIONBUILDER_CLIENT_SECRET'] = 'dummy_secret'
    @original_redirect_uri = ENV['NATIONBUILDER_REDIRECT_URI']
    ENV['NATIONBUILDER_REDIRECT_URI'] = 'http://localhost:3000/auth/nationbuilder/callback'

    # Enable feature flags for OAuth and challenge handling
    @nationbuilder_flag = FeatureFlag.find_or_create_by!(name: 'nationbuilder_signin') do |flag|
      flag.description = 'Test flag for NationBuilder OAuth'
      flag.enabled = true
    end

    @cloudflare_flag = FeatureFlag.find_or_create_by!(name: 'cloudflare_challenge_handling') do |flag|
      flag.description = 'Test flag for Cloudflare challenge handling'
      flag.enabled = true
    end
  end

  after do
    ENV['NATIONBUILDER_NATION_SLUG'] = @original_slug
    ENV['NATIONBUILDER_CLIENT_ID'] = @original_client_id
    ENV['NATIONBUILDER_CLIENT_SECRET'] = @original_client_secret
    ENV['NATIONBUILDER_REDIRECT_URI'] = @original_redirect_uri
  end

  describe 'OAuth to Challenge Flow (Integration Level)' do
    context 'when system creates challenge from OAuth callback' do
      before do
        # Stub the initial OAuth redirect
        stub_request(:any, /nationbuilder\.com/).to_return(status: 200, body: '')

        # Stub the token exchange to return Cloudflare challenge
        turnstile_html = <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Just a moment...</title>
          </head>
          <body>
            <div class="cf-challenge-running">
              <div class="cf-turnstile" data-sitekey="test-site-key-123"></div>
            </div>
          </body>
          </html>
        HTML

        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(status: 403, body: turnstile_html, headers: { 'Content-Type' => 'text/html' })
      end

      it 'processes OAuth callback and creates challenge record' do
        # Verify starting state
        expect(CloudflareChallenge.count).to eq(0)

        # Simulate OAuth callback with authorization code
        visit '/auth/nationbuilder/callback?code=test_oauth_code&state=test_state'

        # Verify database record was created
        expect(CloudflareChallenge.count).to eq(1)
        challenge = CloudflareChallenge.last
        expect(challenge.challenge_type).to eq('turnstile')
        expect(challenge.oauth_state).to eq('test_state')
        expect(challenge.original_params['code']).to eq('test_oauth_code')
        expect(challenge.expired?).to be false

        # Verify redirect to challenge page
        expect(page).to have_current_path(/\/cloudflare_challenges\/[a-f0-9\-]+/)
      end
    end

    context 'when user encounters browser challenge' do
      before do
        stub_request(:any, /nationbuilder\.com/).to_return(status: 200, body: '')

        browser_challenge_html = <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Just a moment...</title>
          </head>
          <body>
            <div class="cf-challenge-running">
              <div class="challenge-stage">
                Browser verification in progress...
              </div>
            </div>
          </body>
          </html>
        HTML

        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(status: 403, body: browser_challenge_html, headers: { 'Content-Type' => 'text/html' })
      end

      it 'displays appropriate browser challenge interface' do
        visit sign_in_path
        click_link 'Sign in with NationBuilder'
        visit '/auth/nationbuilder/callback?code=test_oauth_code&state=test_state'

        expect(page).to have_current_path(/\/cloudflare_challenges\/[a-f0-9\-]+/)
        expect(page).to have_content('Browser Verification Required')
        expect(page).to have_content('browser verification')
        expect(page).to have_content('refresh')
        
        # Browser challenges don't have Turnstile widget
        expect(page).not_to have_selector('.cf-turnstile')
        
        # Submit button should be enabled for browser challenges
        submit_button = find('#challenge-submit-button')
        expect(submit_button).not_to be_disabled

        # Verify correct challenge type in database
        challenge = CloudflareChallenge.last
        expect(challenge.challenge_type).to eq('browser_challenge')
      end
    end

    context 'when user encounters rate limit challenge' do
      before do
        stub_request(:any, /nationbuilder\.com/).to_return(status: 200, body: '')

        rate_limit_html = '<html><body>Too Many Requests</body></html>'

        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(status: 429, body: rate_limit_html, headers: { 'Content-Type' => 'text/html' })
      end

      it 'displays rate limit message and disabled form' do
        visit sign_in_path
        click_link 'Sign in with NationBuilder'
        visit '/auth/nationbuilder/callback?code=test_oauth_code&state=test_state'

        expect(page).to have_current_path(/\/cloudflare_challenges\/[a-f0-9\-]+/)
        expect(page).to have_content('Too Many Requests')
        expect(page).to have_content('many requests')
        expect(page).to have_content('wait')
        
        # Submit button should be disabled for rate limit
        submit_button = find('#challenge-submit-button')
        expect(submit_button).to be_disabled

        # Verify correct challenge type in database
        challenge = CloudflareChallenge.last
        expect(challenge.challenge_type).to eq('rate_limit')
      end
    end
  end

  describe 'Challenge Completion Flow' do
    let(:challenge) do
      create(:cloudflare_challenge,
             challenge_type: 'turnstile',
             oauth_state: 'test_state',
             original_params: { 'code' => 'test_oauth_code', 'state' => 'test_state' },
             session_id: 'test_session_id')
    end

    before do
      # Mock session ID to match challenge
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:id).and_return('test_session_id')
      
      # Stub successful OAuth completion after challenge
      token_response = {
        access_token: 'access123',
        refresh_token: 'refresh123',
        expires_in: 3600,
        scope: 'default'
      }

      profile_response = {
        person: {
          id: 12345,
          email: 'newuser@example.com',
          first_name: 'John',
          last_name: 'Doe'
        }
      }

      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(status: 200, body: token_response.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, 'https://testnation.nationbuilder.com/api/v1/people/me')
        .to_return(status: 200, body: profile_response.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'with successful Turnstile verification' do
      before do
        # Mock successful Turnstile verification
        allow_any_instance_of(TurnstileVerificationService).to receive(:verify).and_return(true)
      end

      it 'completes the full flow from challenge to successful sign-in' do
        # Step 1: Visit challenge page
        visit cloudflare_challenge_path(challenge.challenge_id)
        
        expect(page).to have_content('Security Check Required')
        expect(page).to have_selector('.cf-turnstile')

        # Step 2: Submit challenge form (simulating successful Turnstile)
        click_button 'Continue'

        # Step 3: Should redirect to completion page
        expect(page).to have_current_path(complete_cloudflare_challenge_path(challenge.challenge_id))

        # Step 4: Completion page should redirect to OAuth callback with completion flag
        expect(page).to have_current_path(root_path)
        expect(page).to have_content('Successfully signed in with NationBuilder!')

        # Step 5: Verify user was created and signed in
        new_user = User.find_by(nationbuilder_uid: '12345')
        expect(new_user).to be_present
        expect(new_user.email_address).to eq('newuser@example.com')
        expect(new_user.first_name).to eq('John')
      end
    end

    context 'with failed Turnstile verification' do
      before do
        allow_any_instance_of(TurnstileVerificationService).to receive(:verify).and_return(false)
      end

      it 'shows error and allows retry' do
        visit cloudflare_challenge_path(challenge.challenge_id)
        click_button 'Continue'

        # Should stay on challenge page with error
        expect(page).to have_current_path(verify_cloudflare_challenge_path(challenge.challenge_id))
        expect(page).to have_content('Challenge verification failed')
        expect(page).to have_selector('.cf-turnstile')
      end
    end
  end

  describe 'Error Scenarios' do
    context 'when challenge expires' do
      let(:expired_challenge) do
        create(:cloudflare_challenge,
               challenge_id: SecureRandom.uuid,
               expires_at: 1.hour.ago,
               session_id: 'test_session_id')
      end

      before do
        allow_any_instance_of(ActionDispatch::Request::Session).to receive(:id).and_return('test_session_id')
      end

      it 'redirects to sign-in with error message' do
        visit cloudflare_challenge_path(expired_challenge.challenge_id)

        expect(page).to have_current_path(sign_in_path)
        expect(page).to have_content('Challenge has expired')
      end
    end

    context 'when challenge not found' do
      it 'redirects to sign-in with error message' do
        visit cloudflare_challenge_path('non-existent-id')

        expect(page).to have_current_path(sign_in_path)
        expect(page).to have_content('Challenge not found')
      end
    end

    context 'when session mismatch' do
      let(:wrong_session_challenge) do
        create(:cloudflare_challenge,
               challenge_id: SecureRandom.uuid,
               session_id: 'different-session-id')
      end

      before do
        allow_any_instance_of(ActionDispatch::Request::Session).to receive(:id).and_return('current-session-id')
      end

      it 'redirects to sign-in with error message' do
        visit cloudflare_challenge_path(wrong_session_challenge.challenge_id)

        expect(page).to have_current_path(sign_in_path)
        expect(page).to have_content('Challenge not found')
      end
    end
  end

  describe 'Feature Flag Behavior' do
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

  describe 'Alternative Sign-in Flow' do
    let(:challenge) { create(:cloudflare_challenge) }

    before do
      allow_any_instance_of(ActionDispatch::Request::Session).to receive(:id).and_return(challenge.session_id)
    end

    it 'allows user to return to normal sign-in' do
      visit cloudflare_challenge_path(challenge.challenge_id)
      
      expect(page).to have_link('Try alternative sign-in', href: sign_in_path)
      click_link 'Try alternative sign-in'
      
      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_content('Sign in')
      expect(page).to have_field('email_address')
      expect(page).to have_field('password')
    end
  end
end
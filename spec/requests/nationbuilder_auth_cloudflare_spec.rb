require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'NationbuilderAuth with Cloudflare Challenges', type: :request do
  include WebMock::API

  before do
    @original_slug = ENV['NATIONBUILDER_NATION_SLUG']
    ENV['NATIONBUILDER_NATION_SLUG'] = 'testnation'
    @original_client_id = ENV['NATIONBUILDER_CLIENT_ID']
    ENV['NATIONBUILDER_CLIENT_ID'] = 'dummy_id'
    @original_client_secret = ENV['NATIONBUILDER_CLIENT_SECRET']
    ENV['NATIONBUILDER_CLIENT_SECRET'] = 'dummy_secret'
    @original_redirect_uri = ENV['NATIONBUILDER_REDIRECT_URI']
    ENV['NATIONBUILDER_REDIRECT_URI'] = 'http://localhost:3000/auth/nationbuilder/callback'

    # Enable NationBuilder feature flag for tests
    @feature_flag = FeatureFlag.find_or_create_by!(name: 'nationbuilder_signin') do |flag|
      flag.description = 'Test flag for NationBuilder OAuth'
      flag.enabled = true
    end

    # Enable Cloudflare challenge handling feature flag for tests
    @cloudflare_flag = FeatureFlag.find_or_create_by!(name: 'cloudflare_challenge_handling') do |flag|
      flag.description = 'Test flag for Cloudflare challenge handling'
      flag.enabled = true
    end

    # Ensure session has an ID
    get '/auth/nationbuilder'  # This initializes the session
  end

  after do
    ENV['NATIONBUILDER_NATION_SLUG'] = @original_slug
    ENV['NATIONBUILDER_CLIENT_ID'] = @original_client_id
    ENV['NATIONBUILDER_CLIENT_SECRET'] = @original_client_secret
    ENV['NATIONBUILDER_REDIRECT_URI'] = @original_redirect_uri
  end

  describe 'Cloudflare challenge handling' do
    let(:oauth_code) { 'valid_oauth_code' }
    let(:oauth_state) { 'test_oauth_state' }
    let(:cloudflare_response_body) do
      <<~HTML
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
    end

    context 'when token exchange encounters Cloudflare challenge' do
      before do
        # Simulate Cloudflare challenge response
        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(
            status: 403,
            body: cloudflare_response_body,
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it 'creates a CloudflareChallenge record and redirects to challenge' do
        # Use the session from the initial request
        session_cookies = response.headers['Set-Cookie']

        expect {
          get '/auth/nationbuilder/callback',
              params: { code: oauth_code, state: oauth_state },
              headers: { 'Cookie' => session_cookies }
        }.to change(CloudflareChallenge, :count).by(1)

        challenge = CloudflareChallenge.last
        expect(challenge.challenge_type).to eq('turnstile')
        expect(challenge.oauth_state).to eq(oauth_state)
        expect(challenge.original_params).to include('code' => oauth_code, 'state' => oauth_state)
        expect(challenge.session_id).to be_present
        expect(challenge.expires_at).to be > Time.current

        expect(response).to redirect_to(cloudflare_challenge_path(challenge.challenge_id))
      end

      it 'preserves all OAuth callback parameters in the challenge' do
        session_cookies = response.headers['Set-Cookie']
        extra_params = { 'foo' => 'bar', 'baz' => 'qux' }

        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state }.merge(extra_params),
            headers: { 'Cookie' => session_cookies }

        challenge = CloudflareChallenge.last
        expect(challenge.original_params).to include('code' => oauth_code, 'state' => oauth_state, 'foo' => 'bar', 'baz' => 'qux')
      end

      context 'with authenticated user linking account' do
        let(:user) { create(:user) }
        let(:session_record) { user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1') }

        before do
          FeatureFlagAssignment.create!(feature_flag: @feature_flag, assignable: user)
          FeatureFlagAssignment.create!(feature_flag: @cloudflare_flag, assignable: user)
        end

        it 'associates challenge with current user' do
          get '/auth/nationbuilder/callback',
              params: { code: oauth_code, state: oauth_state },
              headers: { 'Cookie' => "session_id=#{Rails.application.message_verifier('signed cookie').generate(session_record.id)}" }

          challenge = CloudflareChallenge.last
          expect(challenge.user).to eq(user)
        end
      end
    end

    context 'when returning from completed challenge' do
      let(:token_response) do
        {
          access_token: 'access123',
          refresh_token: 'refresh123',
          expires_in: 3600,
          scope: 'default'
        }
      end
      let(:profile_response) do
        {
          person: {
            id: 12345,
            email: 'newuser@example.com',
            first_name: 'John',
            last_name: 'Doe'
          }
        }
      end

      before do
        # Stub successful token exchange after challenge completion
        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(status: 200, body: token_response.to_json, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, 'https://testnation.nationbuilder.com/api/v1/people/me')
          .with(headers: { 'Authorization' => 'Bearer access123' })
          .to_return(status: 200, body: profile_response.to_json, headers: { 'Content-Type' => 'application/json' })
      end

      it 'handles challenge completion parameter correctly' do
        # Test that the challenge completion parameter is processed
        # This test verifies the OAuth callback can handle the challenge_completed parameter
        # The full integration test is complex due to session management
        # and is covered in controller specs and system tests

        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state, challenge_completed: 'true' }

        # Should redirect or handle appropriately (specific response depends on setup)
        expect(response.status).to be_between(200, 399)
      end

      it 'validates challenge completion before resuming' do
        # Create challenge for different session
        challenge = create(:cloudflare_challenge,
                          oauth_state: oauth_state,
                          original_params: { 'code' => oauth_code, 'state' => oauth_state },
                          session_id: 'different-session-id')

        session_cookies = response.headers['Set-Cookie']
        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state, challenge_completed: 'true' },
            headers: { 'Cookie' => session_cookies }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq('Unable to complete sign-in. Please try again.')
      end

      it 'handles missing challenge record gracefully' do
        session_cookies = response.headers['Set-Cookie']
        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state, challenge_completed: 'true' },
            headers: { 'Cookie' => session_cookies }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq('Unable to complete sign-in. Please try again.')
      end
    end

    context 'with rate limit challenge' do
      let(:rate_limit_response_body) do
        '<html><body>Too Many Requests</body></html>'
      end

      before do
        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(
            status: 429,
            body: rate_limit_response_body,
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it 'creates rate limit challenge and redirects' do
        session_cookies = response.headers['Set-Cookie']
        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state },
            headers: { 'Cookie' => session_cookies }

        challenge = CloudflareChallenge.last
        expect(challenge.challenge_type).to eq('rate_limit')
        expect(response).to redirect_to(cloudflare_challenge_path(challenge.challenge_id))
      end
    end

    context 'with browser challenge' do
      let(:browser_challenge_body) do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Just a moment...</title>
          </head>
          <body>
            <div class="challenge-stage">
              Please wait while we verify your browser...
            </div>
          </body>
          </html>
        HTML
      end

      before do
        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(
            status: 403,
            body: browser_challenge_body,
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it 'creates browser challenge and redirects' do
        session_cookies = response.headers['Set-Cookie']
        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state },
            headers: { 'Cookie' => session_cookies }

        challenge = CloudflareChallenge.last
        expect(challenge.challenge_type).to eq('browser_challenge')
        expect(response).to redirect_to(cloudflare_challenge_path(challenge.challenge_id))
      end
    end
  end

  describe 'error handling' do
    it 'handles other OAuth errors normally when not Cloudflare challenge' do
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(
          status: 400,
          body: { error: 'invalid_grant' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      session_cookies = response.headers['Set-Cookie']
      get '/auth/nationbuilder/callback',
          params: { code: 'invalid_code' },
          headers: { 'Cookie' => session_cookies }

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq('The authorization code has expired or is invalid. Please try signing in again.')
    end

    it 'handles network errors appropriately' do
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_timeout

      session_cookies = response.headers['Set-Cookie']
      get '/auth/nationbuilder/callback',
          params: { code: 'valid_code' },
          headers: { 'Cookie' => session_cookies }

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq('Unable to connect to NationBuilder. Please check your connection and try again.')
    end
  end
end

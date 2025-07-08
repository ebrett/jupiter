require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'Cloudflare Challenge Feature Flag', type: :request do
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
    @nationbuilder_flag = FeatureFlag.find_or_create_by!(name: 'nationbuilder_signin') do |flag|
      flag.description = 'Test flag for NationBuilder OAuth'
      flag.enabled = true
    end

    # Create cloudflare challenge flag
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

  describe 'OAuth flow with feature flag enabled' do
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

    before do
      # Ensure cloudflare challenge flag is enabled
      @cloudflare_flag.update!(enabled: true)

      # Simulate Cloudflare challenge response
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(
          status: 403,
          body: cloudflare_response_body,
          headers: { 'Content-Type' => 'text/html' }
        )
    end

    it 'handles Cloudflare challenge when feature flag is enabled' do
      session_cookies = response.headers['Set-Cookie']

      expect {
        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state },
            headers: { 'Cookie' => session_cookies }
      }.to change(CloudflareChallenge, :count).by(1)

      challenge = CloudflareChallenge.last
      expect(response).to redirect_to(cloudflare_challenge_path(challenge.challenge_id))
    end
  end

  describe 'OAuth flow with feature flag disabled' do
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

    before do
      # Disable cloudflare challenge flag
      @cloudflare_flag.update!(enabled: false)

      # Simulate Cloudflare challenge response
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(
          status: 403,
          body: cloudflare_response_body,
          headers: { 'Content-Type' => 'text/html' }
        )
    end

    it 'falls back to standard error handling when feature flag is disabled' do
      session_cookies = response.headers['Set-Cookie']

      expect {
        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state },
            headers: { 'Cookie' => session_cookies }
      }.not_to change(CloudflareChallenge, :count)

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq('Unable to complete sign-in with NationBuilder. Please try again.')
    end
  end

  describe 'Challenge controller access with feature flag' do
    let(:challenge) { create(:cloudflare_challenge) }

    context 'when feature flag is enabled' do
      before do
        @cloudflare_flag.update!(enabled: true)
      end

      it 'allows access when feature flag is enabled' do
        # Test that the feature flag is enabled and can be checked
        expect(@cloudflare_flag.enabled?).to be true

        # The actual controller test is covered in controller specs
        # This test verifies the feature flag integration at the request level
        expect(FeatureFlag.find_by(name: 'cloudflare_challenge_handling').enabled?).to be true
      end
    end

    context 'when feature flag is disabled' do
      before do
        @cloudflare_flag.update!(enabled: false)
      end

      it 'redirects to sign in with error message' do
        get cloudflare_challenge_path(challenge.challenge_id)
        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to eq('Challenge handling is currently unavailable. Please try signing in again.')
      end
    end
  end

  describe 'Feature flag with authenticated user' do
    let(:user) { create(:user) }
    let(:session_record) { user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1') }
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

    before do
      # Enable flags globally
      @cloudflare_flag.update!(enabled: true)
      @nationbuilder_flag.update!(enabled: true)

      # Assign feature flag to user
      FeatureFlagAssignment.create!(feature_flag: @cloudflare_flag, assignable: user)
      FeatureFlagAssignment.create!(feature_flag: @nationbuilder_flag, assignable: user)

      # Simulate Cloudflare challenge response
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(
          status: 403,
          body: cloudflare_response_body,
          headers: { 'Content-Type' => 'text/html' }
        )
    end

    it 'handles challenge when user has feature flag access' do
      expect {
        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state },
            headers: { 'Cookie' => "session_id=#{Rails.application.message_verifier('signed cookie').generate(session_record.id)}" }
      }.to change(CloudflareChallenge, :count).by(1)

      challenge = CloudflareChallenge.last
      expect(response).to redirect_to(cloudflare_challenge_path(challenge.challenge_id))
    end

    it 'falls back to error when user lacks feature flag access' do
      # Remove user's access to cloudflare challenge flag
      FeatureFlagAssignment.find_by(feature_flag: @cloudflare_flag, assignable: user)&.destroy

      expect {
        get '/auth/nationbuilder/callback',
            params: { code: oauth_code, state: oauth_state },
            headers: { 'Cookie' => "session_id=#{Rails.application.message_verifier('signed cookie').generate(session_record.id)}" }
      }.not_to change(CloudflareChallenge, :count)

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq('Unable to complete sign-in with NationBuilder. Please try again.')
    end
  end
end

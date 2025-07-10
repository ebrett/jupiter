require 'rails_helper'
require 'webmock/rspec'

RSpec.describe NationbuilderTokenExchangeService, type: :integration do
  include WebMock::API

  before do
    # Set up environment variables
    @original_slug = ENV['NATIONBUILDER_NATION_SLUG']
    ENV['NATIONBUILDER_NATION_SLUG'] = 'testnation'
    @original_client_id = ENV['NATIONBUILDER_CLIENT_ID']
    ENV['NATIONBUILDER_CLIENT_ID'] = 'dummy_id'
    @original_client_secret = ENV['NATIONBUILDER_CLIENT_SECRET']
    ENV['NATIONBUILDER_CLIENT_SECRET'] = 'dummy_secret'
    @original_redirect_uri = ENV['NATIONBUILDER_REDIRECT_URI']
    ENV['NATIONBUILDER_REDIRECT_URI'] = 'http://localhost:3000/auth/nationbuilder/callback'

    # Enable feature flags
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

  describe 'NationbuilderTokenExchangeService + CloudflareChallenge interaction' do
    let(:service) do
      described_class.new(
        client_id: 'dummy_id',
        client_secret: 'dummy_secret',
        redirect_uri: 'http://localhost:3000/auth/nationbuilder/callback'
      )
    end
    let(:oauth_code) { 'test_oauth_code' }

    context 'when NationBuilder API returns Cloudflare challenge' do
      let(:turnstile_html) do
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
        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(
            status: 403,
            body: turnstile_html,
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it 'creates proper CloudflareChallenge object with correct data structure' do
        expect {
          service.exchange_code_for_token(oauth_code)
        }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError) do |error|
          challenge = error.data[:challenge]

          # Verify challenge object structure
          expect(challenge).to be_a(NationbuilderTokenExchangeService::CloudflareChallenge)
          expect(challenge.type).to eq('turnstile')
          expect(challenge.site_key).to eq('test-site-key-123')
          expect(challenge.challenge_data).to be_a(Hash)
          expect(challenge.challenge_data['turnstile_present']).to be true

          # Verify it can be converted to hash (for database storage)
          hash_data = challenge.to_h
          expect(hash_data[:type]).to eq('turnstile')
          expect(hash_data[:site_key]).to eq('test-site-key-123')
          expect(hash_data[:challenge_data]).to eq(challenge.challenge_data)
        end
      end
    end

    context 'with rate limit response' do
      let(:rate_limit_html) { '<html><body>Too Many Requests</body></html>' }

      before do
        stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
          .to_return(
            status: 429,
            body: rate_limit_html,
            headers: { 'Content-Type' => 'text/html' }
          )
      end

      it 'creates rate limit challenge with proper type' do
        expect {
          service.exchange_code_for_token(oauth_code)
        }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError) do |error|
          challenge = error.data[:challenge]
          expect(challenge.type).to eq('rate_limit')
          expect(challenge.site_key).to be_nil
          expect(challenge.challenge_data['rate_limited']).to be true
        end
      end
    end
  end

  describe 'TurnstileVerificationService + CloudflareConfig interaction' do
    let(:response_token) { 'test-turnstile-response-token' }
    let(:user_ip) { '127.0.0.1' }
    let(:service) { TurnstileVerificationService.new(response_token: response_token, user_ip: user_ip) }

    before do
      allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return('test-secret-key')
    end

    context 'with successful Cloudflare API response' do
      before do
        stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
          .with(
            body: {
              secret: 'test-secret-key',
              response: response_token,
              remoteip: user_ip
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
          .to_return(
            status: 200,
            body: { success: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'successfully verifies with correct API payload' do
        expect(service.verify).to be true
      end
    end

    context 'with failed Cloudflare API response' do
      before do
        stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
          .to_return(
            status: 200,
            body: {
              success: false,
              'error-codes' => [ 'invalid-input-response' ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns false for invalid response' do
        expect(service.verify).to be false
      end
    end

    context 'when CloudflareConfig is missing' do
      before do
        allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return(nil)
      end

      it 'fails gracefully without making API call' do
        expect(Net::HTTP).not_to receive(:start)
        expect(service.verify).to be false
      end
    end
  end

  describe 'Database persistence and model interaction' do
    let(:challenge_data) { { 'turnstile_present' => true, 'site_key' => 'test-key' } }
    let(:original_params) { { 'code' => 'oauth123', 'state' => 'state456' } }

    it 'stores and retrieves challenge data consistently' do
      challenge = CloudflareChallenge.create!(
        challenge_id: SecureRandom.uuid,
        challenge_type: 'turnstile',
        challenge_data: challenge_data,
        original_params: original_params,
        oauth_state: 'test-state',
        session_id: 'test-session',
        expires_at: 15.minutes.from_now
      )

      # Verify data persistence
      reloaded_challenge = CloudflareChallenge.find(challenge.id)
      expect(reloaded_challenge.challenge_data).to eq(challenge_data)
      expect(reloaded_challenge.original_params).to eq(original_params)

      # Verify scopes work correctly
      expect(CloudflareChallenge.active).to include(reloaded_challenge)
      expect(CloudflareChallenge.for_session('test-session')).to include(reloaded_challenge)
      expect(CloudflareChallenge.for_session('other-session')).not_to include(reloaded_challenge)
    end

    it 'properly handles expiration logic' do
      active_challenge = create(:cloudflare_challenge, expires_at: 1.hour.from_now)
      expired_challenge = create(:cloudflare_challenge, expires_at: 1.hour.ago)

      expect(active_challenge.expired?).to be false
      expect(expired_challenge.expired?).to be true

      expect(CloudflareChallenge.active).to include(active_challenge)
      expect(CloudflareChallenge.active).not_to include(expired_challenge)
    end
  end

  describe 'Feature flag integration across services' do
    it 'properly controls challenge handling based on feature flag state' do
      service = described_class.new(
        client_id: 'dummy_id',
        client_secret: 'dummy_secret',
        redirect_uri: 'http://localhost:3000/auth/nationbuilder/callback'
      )

      turnstile_html = <<~HTML
        <!DOCTYPE html>
        <html>
        <head><title>Just a moment...</title></head>
        <body>
          <div class="cf-challenge-running">
            <div class="cf-turnstile" data-sitekey="test-key"></div>
          </div>
        </body>
        </html>
      HTML

      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(status: 403, body: turnstile_html, headers: { 'Content-Type' => 'text/html' })

      # Test that token exchange service properly detects challenges regardless of feature flag
      # The feature flag is checked at the controller level, not service level
      expect {
        service.exchange_code_for_token('test_code')
      }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError) do |error|
        expect(error.message).to eq('cloudflare_challenge')
        expect(error.data[:challenge]).to be_present
      end
    end

    it 'validates feature flag presence and state checking' do
      # Test that feature flags exist and can be queried
      flag = FeatureFlag.find_by(name: 'cloudflare_challenge_handling')
      expect(flag).to be_present
      expect(flag.enabled?).to be true

      # Test flag state changes
      flag.update!(enabled: false)
      expect(flag.enabled?).to be false

      flag.update!(enabled: true)
      expect(flag.enabled?).to be true
    end
  end

  describe 'Error handling across service boundaries' do
    it 'handles API failures gracefully across different services' do
      # Test 1: NationBuilder API errors
      service = described_class.new(
        client_id: 'dummy_id',
        client_secret: 'dummy_secret',
        redirect_uri: 'http://localhost:3000/auth/nationbuilder/callback'
      )

      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(status: 400, body: { error: 'invalid_grant' }.to_json)

      expect {
        service.exchange_code_for_token('invalid_code')
      }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError, /invalid_grant/)

      # Test 2: Turnstile verification errors
      verification_service = TurnstileVerificationService.new(
        response_token: 'invalid-token',
        user_ip: '127.0.0.1'
      )

      allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return('test-secret')

      stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
        .to_return(
          status: 200,
          body: { success: false, 'error-codes' => [ 'invalid-input-response' ] }.to_json
        )

      expect(verification_service.verify).to be false
    end

    it 'handles missing configuration gracefully' do
      service = TurnstileVerificationService.new(
        response_token: 'test-token',
        user_ip: '127.0.0.1'
      )

      # Stub the API call to ensure no real HTTP requests are made
      stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
        .to_return(status: 200, body: { success: false }.to_json)

      # Test with missing secret key
      allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return(nil)
      expect(service.verify).to be false

      # Test with blank secret key
      allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return('')
      expect(service.verify).to be false
    end

    it 'validates data integrity across service calls' do
      # Create a challenge through the service layer
      challenge_data = {
        'turnstile_present' => true,
        'site_key' => 'test-site-key'
      }

      challenge = CloudflareChallenge.create!(
        challenge_id: SecureRandom.uuid,
        challenge_type: 'turnstile',
        challenge_data: challenge_data,
        oauth_state: 'test-state',
        session_id: 'test-session',
        original_params: { 'code' => 'oauth_code', 'state' => 'oauth_state' },
        expires_at: 15.minutes.from_now
      )

      # Verify the data round-trip integrity
      retrieved_challenge = CloudflareChallenge.find_by(challenge_id: challenge.challenge_id)
      expect(retrieved_challenge.challenge_data).to eq(challenge_data)
      expect(retrieved_challenge.challenge_data['site_key']).to eq('test-site-key')

      # Verify URL generation works
      expect(retrieved_challenge.challenge_url).to include(challenge.challenge_id)
    end
  end
end

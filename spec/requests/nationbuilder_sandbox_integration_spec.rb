require 'rails_helper'

RSpec.describe 'NationBuilder Sandbox Integration', type: :request do
  before do
    # These tests are designed to work with VCR cassettes
    # To record new cassettes, set your real sandbox environment variables
    # and replace the dummy tokens below with real ones from your OAuth flow

    # Set dummy environment variables for VCR playback
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('NATIONBUILDER_CLIENT_ID').and_return('test_client_id')
    allow(ENV).to receive(:[]).with('NATIONBUILDER_CLIENT_SECRET').and_return('test_client_secret')
    allow(ENV).to receive(:[]).with('NATIONBUILDER_REDIRECT_URI').and_return('http://localhost:3000/auth/nationbuilder/callback')
    allow(ENV).to receive(:[]).with('NATIONBUILDER_NATION_SLUG').and_return('testnation')
  end

  describe 'OAuth token exchange', :vcr do
    context 'with valid authorization code' do
      let(:authorization_code) { 'valid_sandbox_authorization_code' }

      xit 'successfully exchanges code for access token' do
        VCR.use_cassette('nationbuilder/oauth_token_exchange_success') do
          service = NationbuilderTokenExchangeService.new(
            client_id: ENV['NATIONBUILDER_CLIENT_ID'],
            client_secret: ENV['NATIONBUILDER_CLIENT_SECRET'],
            redirect_uri: ENV['NATIONBUILDER_REDIRECT_URI']
          )

          # This will record the actual sandbox API response on first run
          # and replay it on subsequent runs
          token_data = service.exchange_code_for_token(authorization_code)

          expect(token_data).to include(:access_token)
          expect(token_data).to include(:refresh_token)
          expect(token_data).to include(:expires_in)
          expect(token_data[:scope]).to eq('default')
          expect(token_data[:token_type]).to eq('bearer')
        end
      end
    end

    context 'with invalid authorization code' do
      let(:invalid_code) { 'invalid_code_12345' }

      xit 'raises TokenExchangeError for invalid code' do
        VCR.use_cassette('nationbuilder/oauth_token_exchange_invalid_code') do
          service = NationbuilderTokenExchangeService.new(
            client_id: ENV['NATIONBUILDER_CLIENT_ID'],
            client_secret: ENV['NATIONBUILDER_CLIENT_SECRET'],
            redirect_uri: ENV['NATIONBUILDER_REDIRECT_URI']
          )

          expect {
            service.exchange_code_for_token(invalid_code)
          }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError, /invalid_grant/)
        end
      end
    end
  end

  describe 'User profile fetching', :vcr do
    context 'with valid access token' do
      let(:access_token) { 'valid_sandbox_access_token' }

      xit 'successfully fetches user profile' do
        VCR.use_cassette('nationbuilder/user_profile_fetch_success') do
          user_service = NationbuilderUserService.new(access_token: access_token)

          profile_data = user_service.fetch_user_profile

          expect(profile_data).to include('data')
          expect(profile_data['data']).to include('id')
          expect(profile_data['data']).to include('email')
          # Additional profile fields may vary based on sandbox data
        end
      end
    end

    context 'with expired access token' do
      let(:expired_token) { 'expired_access_token' }

      xit 'raises error for expired token' do
        VCR.use_cassette('nationbuilder/user_profile_fetch_expired_token') do
          user_service = NationbuilderUserService.new(access_token: expired_token)

          expect {
            user_service.fetch_user_profile
          }.to raise_error(NationbuilderOauthErrors::ApiError)
        end
      end
    end
  end

  describe 'Full OAuth flow integration', :vcr do
    xit 'completes the full OAuth flow with sandbox' do
      VCR.use_cassette('nationbuilder/full_oauth_flow_success') do
        # Test the redirect generation
        get '/auth/nationbuilder'

        expect(response).to have_http_status(:redirect)

        redirect_url = URI.parse(response.location)
        expect(redirect_url.host).to eq("#{ENV['NATIONBUILDER_NATION_SLUG']}.nationbuilder.com")
        expect(redirect_url.path).to eq('/oauth/authorize')

        query_params = CGI.parse(redirect_url.query)
        expect(query_params['client_id']).to eq([ ENV['NATIONBUILDER_CLIENT_ID'] ])
        expect(query_params['redirect_uri']).to eq([ ENV['NATIONBUILDER_REDIRECT_URI'] ])
        expect(query_params['response_type']).to eq([ 'code' ])
        expect(query_params['scope']).to eq([ 'default' ])
      end
    end
  end
end

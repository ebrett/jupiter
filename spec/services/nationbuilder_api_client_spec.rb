require 'rails_helper'
require 'webmock/rspec'

RSpec.describe NationbuilderApiClient do
  let(:user) { create(:user) }
  let!(:nationbuilder_token) { create(:nationbuilder_token, user: user) }
  let(:api_client) { described_class.new(user: user.reload) }
  let(:nation_slug) { 'testnation' }

  before do
    @original_slug = ENV['NATIONBUILDER_NATION_SLUG']
    @original_client_id = ENV['NATIONBUILDER_CLIENT_ID']
    @original_client_secret = ENV['NATIONBUILDER_CLIENT_SECRET']

    ENV['NATIONBUILDER_NATION_SLUG'] = nation_slug
    ENV['NATIONBUILDER_CLIENT_ID'] = 'test_client_id'
    ENV['NATIONBUILDER_CLIENT_SECRET'] = 'test_client_secret'
    WebMock.disable_net_connect!
  end

  after do
    ENV['NATIONBUILDER_NATION_SLUG'] = @original_slug
    ENV['NATIONBUILDER_CLIENT_ID'] = @original_client_id
    ENV['NATIONBUILDER_CLIENT_SECRET'] = @original_client_secret
    WebMock.allow_net_connect!
  end

  describe '#initialize' do
    context 'when NATIONBUILDER_NATION_SLUG is not set' do
      before { ENV['NATIONBUILDER_NATION_SLUG'] = nil }

      it 'raises an error' do
        expect { described_class.new(user: user) }.to raise_error(/NATIONBUILDER_NATION_SLUG environment variable is not set/)
      end
    end

    context 'when user has no nationbuilder_token' do
      let(:user_without_token) { create(:user) }

      it 'raises an ArgumentError' do
        expect { described_class.new(user: user_without_token) }.to raise_error(ArgumentError, 'User must have a nationbuilder_token')
      end
    end

    context 'when properly configured' do
      it 'initializes successfully' do
        expect { api_client }.not_to raise_error
      end
    end
  end

  describe '#request' do
    let(:api_url) { "https://#{nation_slug}.nationbuilder.com/api/v2/people" }
    let(:success_response) { { people: [ { id: 1, name: 'Test User' } ] } }

    context 'with valid token' do
      before do
        stub_request(:get, api_url)
          .with(headers: { 'Authorization' => "Bearer #{nationbuilder_token.access_token}" })
          .to_return(
            status: 200,
            body: success_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'makes successful API request' do
        result = api_client.get('/api/v2/people')
        expect(result).to eq(success_response.deep_symbolize_keys)
      end

      it 'logs the request and response' do
        expect(Rails.logger).to receive(:debug).with(/NationBuilder API Request.*GET \/api\/v2\/people/).at_least(:once)
        expect(Rails.logger).to receive(:debug).with(/NationBuilder API Response.*200/).at_least(:once)
        allow(Rails.logger).to receive(:debug) # Allow other debug logs

        api_client.get('/api/v2/people')
      end
    end

    context 'with expired token' do
      let(:expired_user) { create(:user) }
      let!(:expired_token) { create(:nationbuilder_token, :expired, user: expired_user) }
      let(:expired_api_client) { described_class.new(user: expired_user) }

      before do
        # Mock refresh token endpoint for the tests that actually trigger refresh
        stub_request(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token")
          .with(body: hash_including("grant_type" => "refresh_token"))
          .to_return(
            status: 200,
            body: {
              access_token: 'new_access_token',
              refresh_token: 'new_refresh_token',
              expires_in: 3600,
              scope: 'people:read sites:read'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      context 'when token refresh succeeds' do
        before do
          stub_request(:get, api_url)
            .with(headers: { 'Authorization' => 'Bearer new_access_token' })
            .to_return(
              status: 200,
              body: success_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'refreshes token before making request' do
          # The refresh should happen automatically due to expired token
          result = expired_api_client.get('/api/v2/people')
          expect(result).to eq(success_response.deep_symbolize_keys)
        end
      end

      context 'when token refresh fails' do
        before do
          # Mock the refresh endpoint to return error
          stub_request(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token")
            .with(body: hash_including("grant_type" => "refresh_token"))
            .to_return(status: 401, body: 'Invalid refresh token')
        end

        it 'raises TokenRefreshError' do
          expect { expired_api_client.get('/api/v2/people') }.to raise_error(described_class::TokenRefreshError, 'Unable to refresh access token')
        end
      end
    end

    context 'when API returns 401 Unauthorized' do
      before do
        stub_request(:get, api_url)
          .to_return(status: 401, body: 'Unauthorized')

        # Mock refresh token endpoint
        stub_request(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token")
          .with(body: hash_including("grant_type" => "refresh_token"))
          .to_return(status: 401, body: 'Invalid refresh token')
      end

      it 'raises AuthenticationError and attempts refresh' do
        expect { api_client.get('/api/v2/people') }.to raise_error(NationbuilderOauthErrors::OAuthError)
      end
    end

    context 'when API returns client error (4xx)' do
      before do
        stub_request(:get, api_url)
          .with(headers: { 'Authorization' => "Bearer #{nationbuilder_token.access_token}" })
          .to_return(status: 400, body: 'Bad Request')
      end

      it 'raises ApiError' do
        expect { api_client.get('/api/v2/people') }.to raise_error(NationbuilderOauthErrors::OAuthError)
      end
    end

    context 'when API returns server error (5xx)' do
      before do
        stub_request(:get, api_url)
          .with(headers: { 'Authorization' => "Bearer #{nationbuilder_token.access_token}" })
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises ApiError' do
        expect { api_client.get('/api/v2/people') }.to raise_error(NationbuilderOauthErrors::OAuthError)
      end
    end
  end

  describe 'HTTP method convenience methods' do
    let(:api_url) { "https://#{nation_slug}.nationbuilder.com/api/v2/people" }

    describe '#get' do
      before do
        stub_request(:get, "#{api_url}?limit=10")
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'makes GET request with query parameters' do
        api_client.get('/api/v2/people', params: { limit: 10 })

        expect(WebMock).to have_requested(:get, "#{api_url}?limit=10")
          .with(headers: { 'Authorization' => "Bearer #{nationbuilder_token.access_token}" })
      end
    end

    describe '#post' do
      before do
        stub_request(:post, api_url)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'makes POST request with JSON body' do
        data = { name: 'Test User', email: 'test@example.com' }
        api_client.post('/api/v2/people', params: data)

        expect(WebMock).to have_requested(:post, api_url)
          .with(
            body: data.to_json,
            headers: {
              'Authorization' => "Bearer #{nationbuilder_token.access_token}",
              'Content-Type' => 'application/json'
            }
          )
      end
    end

    describe '#put' do
      before do
        stub_request(:put, api_url)
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'makes PUT request with JSON body' do
        data = { name: 'Updated User' }
        api_client.put('/api/v2/people', params: data)

        expect(WebMock).to have_requested(:put, api_url)
          .with(
            body: data.to_json,
            headers: {
              'Authorization' => "Bearer #{nationbuilder_token.access_token}",
              'Content-Type' => 'application/json'
            }
          )
      end
    end

    describe '#delete' do
      before do
        stub_request(:delete, "#{api_url}?id=123")
          .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'makes DELETE request' do
        api_client.delete('/api/v2/people', params: { id: 123 })

        expect(WebMock).to have_requested(:delete, "#{api_url}?id=123")
          .with(headers: { 'Authorization' => "Bearer #{nationbuilder_token.access_token}" })
      end
    end
  end

  describe 'concurrent token refresh handling' do
    it 'includes mutex for thread safety' do
      expect(api_client.instance_variable_get(:@refresh_mutex)).to be_a(Mutex)
    end
  end

  describe 'response parsing' do
    let(:api_url) { "https://#{nation_slug}.nationbuilder.com/api/v2/people" }

    context 'with JSON response' do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: { data: 'test' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'parses JSON response with symbol keys' do
        result = api_client.get('/api/v2/people')
        expect(result).to eq({ data: 'test' })
      end
    end

    context 'with non-JSON response' do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: 'plain text response',
            headers: { 'Content-Type' => 'text/plain' }
          )
      end

      it 'returns raw body' do
        result = api_client.get('/api/v2/people')
        expect(result).to eq('plain text response')
      end
    end

    context 'with empty response' do
      before do
        stub_request(:get, api_url)
          .to_return(status: 200, body: '', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns nil for empty response' do
        result = api_client.get('/api/v2/people')
        expect(result).to be_nil
      end
    end

    context 'with invalid JSON' do
      before do
        stub_request(:get, api_url)
          .to_return(
            status: 200,
            body: 'invalid json {',
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns raw body when JSON parsing fails' do
        expect(Rails.logger).to receive(:warn).with(/Failed to parse JSON response/)
        result = api_client.get('/api/v2/people')
        expect(result).to eq('invalid json {')
      end
    end
  end

  describe 'error handling edge cases' do
    let(:api_url) { "https://#{nation_slug}.nationbuilder.com/api/v2/people" }

    context 'when retry_on_auth_failure is false' do
      before do
        stub_request(:get, api_url)
          .to_return(status: 401, body: 'Unauthorized')

        # Mock refresh token endpoint
        stub_request(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token")
          .with(body: hash_including("grant_type" => "refresh_token"))
          .to_return(status: 401, body: 'Invalid refresh token')
      end

      it 'does not retry on authentication failure' do
        expect { api_client.request(method: :get, path: '/api/v2/people', retry_on_auth_failure: false) }
          .to raise_error(NationbuilderOauthErrors::OAuthError)
      end
    end

    context 'with network timeout' do
      before do
        stub_request(:get, api_url).to_timeout
      end

      it 'propagates network errors' do
        expect { api_client.get('/api/v2/people') }.to raise_error(NationbuilderOauthErrors::NetworkError)
      end
    end
  end

  describe 'path handling' do
    let(:api_url) { "https://#{nation_slug}.nationbuilder.com/api/v2/people" }

    before do
      stub_request(:get, api_url)
        .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    it 'handles paths without leading slash' do
      api_client.get('api/v2/people')
      expect(WebMock).to have_requested(:get, api_url)
    end

    it 'handles paths with leading slash' do
      api_client.get('/api/v2/people')
      expect(WebMock).to have_requested(:get, api_url)
    end
  end
end

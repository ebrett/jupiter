require 'rails_helper'
require 'webmock/rspec'

RSpec.describe NationbuilderTokenRefreshService do
  let(:client_id) { 'test_client_id' }
  let(:client_secret) { 'test_client_secret' }
  let(:nation_slug) { 'testorg' }
  let(:user) { create(:user) }
  let(:nationbuilder_token) do
    create(:nationbuilder_token,
           user: user,
           access_token: 'old_access_token',
           refresh_token: 'valid_refresh_token',
           expires_at: 1.hour.ago)
  end

  let(:service) do
    described_class.new(
      client_id: client_id,
      client_secret: client_secret
    )
  end

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('NATIONBUILDER_NATION_SLUG').and_return(nation_slug)
  end

  describe '#initialize' do
    context 'when NATIONBUILDER_NATION_SLUG is not set' do
      before do
        allow(ENV).to receive(:[]).with('NATIONBUILDER_NATION_SLUG').and_return(nil)
      end

      it 'raises an error' do
        expect {
          described_class.new(client_id: client_id, client_secret: client_secret)
        }.to raise_error('NATIONBUILDER_NATION_SLUG environment variable is not set')
      end
    end
  end

  describe '#refresh_token' do
    let(:success_response_body) do
      {
        access_token: 'new_access_token',
        refresh_token: 'new_refresh_token',
        expires_in: 3600,
        scope: 'read write'
      }.to_json
    end


    context 'when refresh is successful' do
      before do
        stub_request(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token")
          .with(
            body: {
              client_id: client_id,
              client_secret: client_secret,
              refresh_token: 'valid_refresh_token',
              grant_type: 'refresh_token'
            }
          )
          .to_return(status: 200, body: success_response_body, headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns true' do
        result = service.refresh_token(nationbuilder_token)
        expect(result).to be true
      end

      it 'updates the token with new values' do
        expect {
          service.refresh_token(nationbuilder_token)
        }.to change { nationbuilder_token.reload.access_token }.to('new_access_token')
          .and change { nationbuilder_token.reload.refresh_token }.to('new_refresh_token')
      end

      it 'updates the expiration time' do
        travel_to Time.current do
          service.refresh_token(nationbuilder_token)
          expected_expires_at = Time.current + 3600.seconds
          expect(nationbuilder_token.reload.expires_at).to be_within(1.second).of(expected_expires_at)
        end
      end

      it 'logs successful refresh' do
        expect(Rails.logger).to receive(:info).with("Token refresh successful for user #{user.id}")
        service.refresh_token(nationbuilder_token)
      end
    end

    context 'when refresh token is blank' do
      before do
        # Bypass validations to set blank refresh token for testing
        nationbuilder_token.update_column(:refresh_token, '')
      end

      it 'returns false without making a request' do
        expect(Net::HTTP).not_to receive(:start)
        result = service.refresh_token(nationbuilder_token)
        expect(result).to be false
      end
    end

    context 'when API returns 401 Unauthorized' do
      before do
        stub_request(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token")
          .to_return(status: 401, body: '{"error": "invalid_grant"}', headers: { 'Content-Type' => 'application/json' })
      end

      it 'returns false' do
        result = service.refresh_token(nationbuilder_token)
        expect(result).to be false
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/Token refresh failed for user #{user.id}/).at_least(:once)
        service.refresh_token(nationbuilder_token)
      end

      it 'does not retry on auth errors' do
        result = service.refresh_token(nationbuilder_token)
        expect(result).to be false
        
        # Verify the request was made only once (no retries for auth errors)
        expect(WebMock).to have_requested(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token").once
      end
    end

    context 'when API returns 500 Server Error' do
      before do
        stub_request(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token")
          .to_return(status: 500, body: 'Internal Server Error')
      end

      it 'retries with exponential backoff' do
        expect(service).to receive(:sleep).exactly(3).times
        
        result = service.refresh_token(nationbuilder_token)
        expect(result).to be false
        
        # Verify the request was made 4 times (1 initial + 3 retries)
        expect(WebMock).to have_requested(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token").times(4)
      end
    end

    context 'when network error occurs' do
      before do
        stub_request(:post, "https://#{nation_slug}.nationbuilder.com/oauth/token")
          .to_raise(SocketError.new('Network unreachable'))
      end

      it 'returns false and logs the error' do
        expect(Rails.logger).to receive(:error).at_least(:once)
        result = service.refresh_token(nationbuilder_token)
        expect(result).to be false
      end
    end
  end

  describe 'exponential backoff' do
    let(:service_instance) { service.send(:new) }

    it 'increases delay exponentially with jitter' do
      # Access private method for testing
      delay1 = service.send(:exponential_backoff_delay, 1)
      delay2 = service.send(:exponential_backoff_delay, 2)
      delay3 = service.send(:exponential_backoff_delay, 3)

      expect(delay1).to be_between(1.0, 1.3) # Base delay with jitter
      expect(delay2).to be_between(2.0, 2.6) # 2x base with jitter
      expect(delay3).to be_between(4.0, 5.2) # 4x base with jitter
    end

    it 'caps delay at maximum' do
      delay = service.send(:exponential_backoff_delay, 10)
      expect(delay).to be <= 20.8 # Max delay (16.0) with max jitter (1.3)
    end
  end
end
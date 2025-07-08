require 'rails_helper'

RSpec.describe TurnstileVerificationService do
  let(:response_token) { 'test-turnstile-response-token' }
  let(:user_ip) { '127.0.0.1' }
  let(:service) { described_class.new(response_token: response_token, user_ip: user_ip) }

  describe '#initialize' do
    it 'sets response_token and user_ip' do
      expect(service.instance_variable_get(:@response_token)).to eq(response_token)
      expect(service.instance_variable_get(:@user_ip)).to eq(user_ip)
    end

    it 'retrieves secret key from configuration' do
      allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return('test-secret-key')
      service = described_class.new(response_token: response_token, user_ip: user_ip)
      expect(service.instance_variable_get(:@secret_key)).to eq('test-secret-key')
    end
  end

  describe '#verify' do
    let(:api_endpoint) { 'https://challenges.cloudflare.com/turnstile/v0/siteverify' }

    before do
      allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return('test-secret-key')
    end

    context 'with valid response token' do
      it 'returns true for successful verification' do
        successful_response = instance_double(Net::HTTPSuccess)
        allow(successful_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(successful_response).to receive(:body).and_return('{"success":true}')

        mock_http = double('http')
        allow(mock_http).to receive(:request).and_return(successful_response)
        allow(Net::HTTP).to receive(:start).and_yield(mock_http)

        expect(service.verify).to be true
      end

      it 'makes correct API request to Cloudflare' do
        mock_http = double('http')
        mock_request = instance_double(Net::HTTP::Post)
        mock_response = instance_double(Net::HTTPSuccess)

        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
        allow(mock_request).to receive(:[]=)
        allow(mock_request).to receive(:body=)
        allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(mock_response).to receive(:body).and_return('{"success":true}')

        expect(Net::HTTP).to receive(:start)
          .with('challenges.cloudflare.com', 443, use_ssl: true)
          .and_yield(mock_http)
        expect(mock_http).to receive(:request).with(mock_request).and_return(mock_response)

        service.verify
      end

      it 'sends correct payload in request' do
        mock_request = instance_double(Net::HTTP::Post)
        allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)

        expect(mock_request).to receive(:[]=).with('Content-Type', 'application/json')
        expect(mock_request).to receive(:body=).with({
          secret: 'test-secret-key',
          response: response_token,
          remoteip: user_ip
        }.to_json)

        allow(Net::HTTP).to receive(:start).and_return(
          instance_double(Net::HTTPSuccess, is_a?: true, body: '{"success":true}')
        )

        service.verify
      end
    end

    context 'with invalid response token' do
      it 'returns false for failed verification' do
        failed_response = instance_double(Net::HTTPSuccess)
        allow(failed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(failed_response).to receive(:body).and_return('{"success":false,"error-codes":["invalid-input-response"]}')

        allow(Net::HTTP).to receive(:start).and_return(failed_response)

        expect(service.verify).to be false
      end
    end

    context 'with missing response token' do
      let(:response_token) { nil }

      it 'returns false without making API call' do
        expect(Net::HTTP).not_to receive(:start)
        expect(service.verify).to be false
      end
    end

    context 'with blank response token' do
      let(:response_token) { '' }

      it 'returns false without making API call' do
        expect(Net::HTTP).not_to receive(:start)
        expect(service.verify).to be false
      end
    end

    context 'with missing secret key' do
      before do
        allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return(nil)
      end

      it 'returns false without making API call' do
        expect(Net::HTTP).not_to receive(:start)
        expect(service.verify).to be false
      end
    end

    context 'when API request fails' do
      before do
        allow(CloudflareConfig).to receive(:turnstile_secret_key).and_return('test-secret-key')
      end

      it 'returns false for non-success HTTP response' do
        failed_response = instance_double(Net::HTTPClientError)
        allow(failed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(failed_response).to receive_messages(code: '400', body: 'Bad Request')

        allow(Net::HTTP).to receive(:start).and_return(failed_response)

        expect(Rails.logger).to receive(:error).with(/Turnstile verification failed: 400 Bad Request/)
        expect(service.verify).to be false
      end

      it 'returns false and logs error when exception occurs' do
        allow(Net::HTTP).to receive(:start).and_raise(StandardError.new('Network error'))

        expect(Rails.logger).to receive(:error).with(/Turnstile verification error: Network error/)
        expect(service.verify).to be false
      end
    end

    context 'when API returns malformed JSON' do
      it 'returns false and logs error' do
        malformed_response = instance_double(Net::HTTPSuccess)
        allow(malformed_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(malformed_response).to receive(:body).and_return('invalid json')

        allow(Net::HTTP).to receive(:start).and_return(malformed_response)

        expect(Rails.logger).to receive(:error).with(/Turnstile verification error:/)
        expect(service.verify).to be false
      end
    end
  end
end

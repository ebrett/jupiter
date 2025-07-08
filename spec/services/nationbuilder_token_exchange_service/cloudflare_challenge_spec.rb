require 'rails_helper'

RSpec.describe NationbuilderTokenExchangeService::CloudflareChallenge do
  describe '.from_response' do
    context 'with Turnstile challenge response' do
      let(:turnstile_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Just a moment...</title>
          </head>
          <body>
            <div class="cf-challenge-running">
              <div class="cf-turnstile" data-sitekey="0x4AAAAAAABkMYinukHgb" data-callback="onloadTurnstileCallback">
              </div>
            </div>
          </body>
          </html>
        HTML
      end

      let(:response) do
        instance_double(Net::HTTPResponse, code: '403', body: turnstile_html)
      end

      it 'creates challenge object with turnstile type' do
        challenge = described_class.from_response(response)

        expect(challenge.type).to eq('turnstile')
        expect(challenge.site_key).to eq('0x4AAAAAAABkMYinukHgb')
        expect(challenge.challenge_data).to include('turnstile_present' => true)
      end

      it 'extracts site key from data-sitekey attribute' do
        challenge = described_class.from_response(response)

        expect(challenge.site_key).to eq('0x4AAAAAAABkMYinukHgb')
      end
    end

    context 'with browser challenge response' do
      let(:browser_challenge_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Just a moment...</title>
          </head>
          <body>
            <div class="cf-challenge-running">
              <div id="challenge-stage">
                <div class="challenge-spinner"></div>
              </div>
            </div>
          </body>
          </html>
        HTML
      end

      let(:response) do
        instance_double(Net::HTTPResponse, code: '403', body: browser_challenge_html)
      end

      it 'creates challenge object with browser_challenge type' do
        challenge = described_class.from_response(response)

        expect(challenge.type).to eq('browser_challenge')
        expect(challenge.site_key).to be_nil
        expect(challenge.challenge_data).to include('challenge_stage_present' => true)
      end
    end

    context 'with rate limit response' do
      let(:rate_limit_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Rate limited</title>
          </head>
          <body>
            <h1>Rate limited</h1>
            <p>Too many requests. Please wait.</p>
          </body>
          </html>
        HTML
      end

      let(:response) do
        instance_double(Net::HTTPResponse, code: '429', body: rate_limit_html)
      end

      it 'creates challenge object with rate_limit type' do
        challenge = described_class.from_response(response)

        expect(challenge.type).to eq('rate_limit')
        expect(challenge.site_key).to be_nil
        expect(challenge.challenge_data).to include('rate_limited' => true)
      end
    end

    context 'with legacy "Just a moment" response' do
      let(:legacy_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <title>Just a moment...</title>
          </head>
          <body>
            <div>Just a moment...</div>
          </body>
          </html>
        HTML
      end

      let(:response) do
        instance_double(Net::HTTPResponse, code: '403', body: legacy_html)
      end

      it 'creates challenge object with browser_challenge type for legacy detection' do
        challenge = described_class.from_response(response)

        expect(challenge.type).to eq('browser_challenge')
        expect(challenge.site_key).to be_nil
        expect(challenge.challenge_data).to include('legacy_detection' => true)
      end
    end

    context 'with non-challenge response' do
      let(:normal_error) do
        instance_double(Net::HTTPResponse, code: '400', body: '{"error": "invalid_request"}')
      end

      it 'returns nil for non-challenge responses' do
        challenge = described_class.from_response(normal_error)

        expect(challenge).to be_nil
      end
    end
  end

  describe '#initialize' do
    it 'sets type, site_key, and challenge_data' do
      challenge = described_class.new(
        type: 'turnstile',
        site_key: 'test-key',
        challenge_data: { 'test' => true }
      )

      expect(challenge.type).to eq('turnstile')
      expect(challenge.site_key).to eq('test-key')
      expect(challenge.challenge_data).to eq({ 'test' => true })
    end

    it 'allows nil site_key for browser challenges' do
      challenge = described_class.new(
        type: 'browser_challenge',
        site_key: nil,
        challenge_data: {}
      )

      expect(challenge.type).to eq('browser_challenge')
      expect(challenge.site_key).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns hash representation of challenge' do
      challenge = described_class.new(
        type: 'turnstile',
        site_key: 'test-key',
        challenge_data: { 'turnstile_present' => true }
      )

      hash = challenge.to_h

      expect(hash).to eq({
        type: 'turnstile',
        site_key: 'test-key',
        challenge_data: { 'turnstile_present' => true }
      })
    end
  end
end

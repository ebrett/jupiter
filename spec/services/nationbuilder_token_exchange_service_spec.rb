require 'rails_helper'
require 'webmock/rspec'

RSpec.describe NationbuilderTokenExchangeService do
  let(:client_id) { 'dummy_id' }
  let(:client_secret) { 'dummy_secret' }
  let(:redirect_uri) { 'https://example.com/callback' }
  let(:code) { 'dummy_code' }
  let(:nation_slug) { 'testnation' }
  let(:token_url) { "https://#{nation_slug}.nationbuilder.com/oauth/token" }

  let(:token_response) do
    {
      access_token: 'access123',
      refresh_token: 'refresh123',
      expires_in: 3600,
      scope: 'people:read sites:read'
    }
  end

  before do
    stub_request(:post, token_url)
      .with(
        body: hash_including(
          client_id: client_id,
          client_secret: client_secret,
          redirect_uri: redirect_uri,
          code: code,
          grant_type: 'authorization_code'
        )
      )
      .to_return(
        status: 200,
        body: token_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    allow(ENV).to receive(:[]).with('NATIONBUILDER_NATION_SLUG').and_return(nation_slug)
  end

  it 'exchanges authorization code for tokens' do
    service = described_class.new(
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri
    )
    result = service.exchange_code_for_token(code)
    expect(result[:access_token]).to eq('access123')
    expect(result[:refresh_token]).to eq('refresh123')
    expect(result[:expires_in]).to eq(3600)
    expect(result[:scope]).to eq('people:read sites:read')
  end

  it 'raises TokenExchangeError if the token exchange response is invalid' do
    stub_request(:post, token_url).to_return(
      status: 400,
      body: { error: 'invalid_grant' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    service = described_class.new(
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri
    )

    expect {
      service.exchange_code_for_token('bad_code')
    }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError, /invalid_grant/)
  end

  describe 'Cloudflare challenge detection' do
    let(:service) do
      described_class.new(
        client_id: client_id,
        client_secret: client_secret,
        redirect_uri: redirect_uri
      )
    end

    context 'when encountering Turnstile challenge' do
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

      it 'raises TokenExchangeError with challenge data' do
        stub_request(:post, token_url).to_return(
          status: 403,
          body: turnstile_html,
          headers: { 'Content-Type' => 'text/html' }
        )

        expect {
          service.exchange_code_for_token(code)
        }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError) do |error|
          expect(error.message).to eq('cloudflare_challenge')
          expect(error.data[:challenge]).to be_a(NationbuilderTokenExchangeService::CloudflareChallenge)
          expect(error.data[:challenge].type).to eq('turnstile')
          expect(error.data[:challenge].site_key).to eq('0x4AAAAAAABkMYinukHgb')
        end
      end
    end

    context 'when encountering browser challenge' do
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

      it 'raises TokenExchangeError with browser challenge data' do
        stub_request(:post, token_url).to_return(
          status: 403,
          body: browser_challenge_html,
          headers: { 'Content-Type' => 'text/html' }
        )

        expect {
          service.exchange_code_for_token(code)
        }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError) do |error|
          expect(error.message).to eq('cloudflare_challenge')
          expect(error.data[:challenge]).to be_a(NationbuilderTokenExchangeService::CloudflareChallenge)
          expect(error.data[:challenge].type).to eq('browser_challenge')
          expect(error.data[:challenge].site_key).to be_nil
        end
      end
    end

    context 'when encountering rate limit' do
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

      it 'raises TokenExchangeError with rate limit challenge data' do
        stub_request(:post, token_url).to_return(
          status: 429,
          body: rate_limit_html,
          headers: { 'Content-Type' => 'text/html' }
        )

        expect {
          service.exchange_code_for_token(code)
        }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError) do |error|
          expect(error.message).to eq('cloudflare_challenge')
          expect(error.data[:challenge]).to be_a(NationbuilderTokenExchangeService::CloudflareChallenge)
          expect(error.data[:challenge].type).to eq('rate_limit')
        end
      end
    end

    context 'when encountering legacy challenge detection' do
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

      it 'maintains backward compatibility with legacy detection' do
        stub_request(:post, token_url).to_return(
          status: 403,
          body: legacy_html,
          headers: { 'Content-Type' => 'text/html' }
        )

        expect {
          service.exchange_code_for_token(code)
        }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError) do |error|
          expect(error.message).to eq('cloudflare_challenge')
          expect(error.data[:challenge].type).to eq('browser_challenge')
          expect(error.data[:challenge].challenge_data['legacy_detection']).to be true
        end
      end
    end
  end
end

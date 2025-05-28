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
    }.to raise_error(NationbuilderTokenExchangeService::TokenExchangeError, /Token exchange failed/)
  end
end

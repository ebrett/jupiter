require 'rails_helper'
require 'webmock/rspec'

RSpec.describe 'NationbuilderAuthController', type: :request do
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
  end

  after do
    ENV['NATIONBUILDER_NATION_SLUG'] = @original_slug
    ENV['NATIONBUILDER_CLIENT_ID'] = @original_client_id
    ENV['NATIONBUILDER_CLIENT_SECRET'] = @original_client_secret
    ENV['NATIONBUILDER_REDIRECT_URI'] = @original_redirect_uri
  end

  describe 'GET /auth/nationbuilder/callback' do
    let(:user) { User.create!(email_address: 'test@example.com', password: 'password', password_confirmation: 'password') }
    let(:session_record) { user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1') }

    it 'redirects to root with alert if error param is present' do
      get '/auth/nationbuilder/callback', params: { error: 'access_denied', error_description: 'User denied access' }, 
          headers: { 'Cookie' => "session_id=#{Rails.application.message_verifier('signed cookie').generate(session_record.id)}" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('OAuth error: User denied access')
    end

    it 'redirects to root with alert if code param is missing' do
      get '/auth/nationbuilder/callback', 
          headers: { 'Cookie' => "session_id=#{Rails.application.message_verifier('signed cookie').generate(session_record.id)}" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('No authorization code received.')
    end

    it 'stores tokens and redirects with notice on successful token exchange' do
      token_response = {
        access_token: 'access123',
        refresh_token: 'refresh123',
        expires_in: 3600,
        scope: 'people:read sites:read'
      }
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(status: 200, body: token_response.to_json, headers: { 'Content-Type' => 'application/json' })

      get '/auth/nationbuilder/callback', params: { code: 'valid_code' }, 
          headers: { 'Cookie' => "session_id=#{Rails.application.message_verifier('signed cookie').generate(session_record.id)}" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('Nationbuilder authentication successful.')

      token = user.nationbuilder_tokens.first
      expect(token).to be_present
      expect(token.access_token).to eq('access123')
      expect(token.refresh_token).to eq('refresh123')
      expect(token.scope).to eq('people:read sites:read')
    end

    it 'handles token exchange failure gracefully' do
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(status: 400, body: { error: 'invalid_grant' }.to_json, headers: { 'Content-Type' => 'application/json' })

      get '/auth/nationbuilder/callback', params: { code: 'invalid_code' }, 
          headers: { 'Cookie' => "session_id=#{Rails.application.message_verifier('signed cookie').generate(session_record.id)}" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('Nationbuilder token exchange failed:')
    end

    it 'redirects to login if not authenticated' do
      get '/auth/nationbuilder/callback', params: { code: 'valid_code' }
      expect(response).to redirect_to('/session/new')
    end
  end
end 
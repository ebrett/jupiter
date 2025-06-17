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
        scope: 'default'
      }
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(status: 200, body: token_response.to_json, headers: { 'Content-Type' => 'application/json' })

      # Stub the user profile fetch
      profile_response = {
        person: {
          id: 12345,
          email: 'test@example.com',
          first_name: 'Test',
          last_name: 'User',
          phone: '555-123-4567',
          tags: [ 'member', 'volunteer' ]
        }
      }
      stub_request(:get, 'https://testnation.nationbuilder.com/api/v1/people/me')
        .with(headers: { 'Authorization' => 'Bearer access123' })
        .to_return(status: 200, body: profile_response.to_json, headers: { 'Content-Type' => 'application/json' })

      # No session cookie for new OAuth user
      get '/auth/nationbuilder/callback', params: { code: 'valid_code' }
      expect(response).to redirect_to(root_path)

      # Verify user and token creation
      oauth_user = User.find_by(email_address: 'test@example.com')
      expect(oauth_user).to be_present

      token = oauth_user.nationbuilder_tokens.first
      expect(token).to be_present
      expect(token.access_token).to eq('access123')
    end

    it 'handles token exchange failure gracefully' do
      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(status: 400, body: { error: 'invalid_grant' }.to_json, headers: { 'Content-Type' => 'application/json' })

      get '/auth/nationbuilder/callback', params: { code: 'invalid_code' },
          headers: { 'Cookie' => "session_id=#{Rails.application.message_verifier('signed cookie').generate(session_record.id)}" }
      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include('The authorization code has expired or is invalid')
    end

    it 'creates new user and session when not authenticated' do
      token_response = {
        access_token: 'access123',
        refresh_token: 'refresh123',
        expires_in: 3600,
        scope: 'default'
      }

      profile_response = {
        person: {
          id: 12345,
          email: 'newuser@example.com',
          first_name: 'John',
          last_name: 'Doe'
        }
      }

      stub_request(:post, 'https://testnation.nationbuilder.com/oauth/token')
        .to_return(status: 200, body: token_response.to_json, headers: { 'Content-Type' => 'application/json' })

      stub_request(:get, 'https://testnation.nationbuilder.com/api/v1/people/me')
        .with(headers: { 'Authorization' => 'Bearer access123' })
        .to_return(status: 200, body: profile_response.to_json, headers: { 'Content-Type' => 'application/json' })

      expect {
        get '/auth/nationbuilder/callback', params: { code: 'valid_code' }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('Successfully signed in with NationBuilder!')

      new_user = User.find_by(nationbuilder_uid: '12345')
      expect(new_user).to be_present
      expect(new_user.email_address).to eq('newuser@example.com')
      expect(new_user.first_name).to eq('John')
      expect(new_user.last_name).to eq('Doe')
      expect(new_user.nationbuilder_tokens.first).to be_present
    end
  end
end

require 'rails_helper'

RSpec.describe 'NationbuilderAuthController', type: :request do
  before do
    @original_slug = ENV['NATIONBUILDER_NATION_SLUG']
    ENV['NATIONBUILDER_NATION_SLUG'] = 'testnation'
    @original_client_id = ENV['NATIONBUILDER_CLIENT_ID']
    ENV['NATIONBUILDER_CLIENT_ID'] = 'dummy_id'
    @original_client_secret = ENV['NATIONBUILDER_CLIENT_SECRET']
    ENV['NATIONBUILDER_CLIENT_SECRET'] = 'dummy_secret'
    @original_redirect_uri = ENV['NATIONBUILDER_REDIRECT_URI']
    ENV['NATIONBUILDER_REDIRECT_URI'] = 'https://example.com/callback'
  end

  after do
    ENV['NATIONBUILDER_NATION_SLUG'] = @original_slug
    ENV['NATIONBUILDER_CLIENT_ID'] = @original_client_id
    ENV['NATIONBUILDER_CLIENT_SECRET'] = @original_client_secret
    ENV['NATIONBUILDER_REDIRECT_URI'] = @original_redirect_uri
  end

  describe 'GET /auth/nationbuilder' do
    it 'redirects to the Nationbuilder authorization URL' do
      get '/auth/nationbuilder'
      expect(response).to have_http_status(:redirect)
      expect(response.headers['Location']).to start_with('https://testnation.nationbuilder.com/oauth/authorize?')
      expect(response.headers['Location']).to include('client_id=dummy_id')
      expect(response.headers['Location']).to include('redirect_uri=https%3A%2F%2Fexample.com%2Fcallback')
    end
  end

  describe 'GET /auth/nationbuilder/callback' do
    it 'redirects to root with alert if error param is present' do
      get '/auth/nationbuilder/callback', params: { error: 'access_denied', error_description: 'User denied access' }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('OAuth error: User denied access')
    end

    it 'redirects to root with alert if code param is missing' do
      get '/auth/nationbuilder/callback'
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include('No authorization code received.')
    end
  end
end 
require 'rails_helper'

describe Oauth2Client do
  subject do
    described_class.new(
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri,
      scopes: scopes
    )
  end

  let(:client_id) { 'dummy_id' }
  let(:client_secret) { 'dummy_secret' }
  let(:redirect_uri) { 'https://example.com/callback' }
  let(:scopes) { [ 'people:read', 'sites:read' ] }

  before do
    @original_slug = ENV['NATIONBUILDER_NATION_SLUG']
    ENV['NATIONBUILDER_NATION_SLUG'] = 'testnation'
  end

  after do
    ENV['NATIONBUILDER_NATION_SLUG'] = @original_slug
  end


  describe '#authorization_url' do
    it 'generates the correct Nationbuilder OAuth2 authorization URL' do
      url = subject.authorization_url(state: 'teststate')
      expect(url).to include('client_id=dummy_id')
      expect(url).to include('redirect_uri=https%3A%2F%2Fexample.com%2Fcallback')
      expect(url).to include('response_type=code')
      expect(url).to include('scope=people%3Aread+sites%3Aread')
      expect(url).to include('state=teststate')
      expect(url).to start_with('https://testnation.nationbuilder.com/oauth/authorize?')
    end
  end
end

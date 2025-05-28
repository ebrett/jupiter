require 'rails_helper'

RSpec.describe NationbuilderToken, type: :model do
  let(:user) { create(:user) }
  
  describe 'associations' do
    it 'belongs to user' do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    it 'validates presence of access_token' do
      token = build(:nationbuilder_token, access_token: nil)
      expect(token).not_to be_valid
      expect(token.errors[:access_token]).to include("can't be blank")
    end

    it 'validates presence of refresh_token' do
      token = build(:nationbuilder_token, refresh_token: nil)
      expect(token).not_to be_valid
      expect(token.errors[:refresh_token]).to include("can't be blank")
    end

    it 'validates presence of expires_at' do
      token = build(:nationbuilder_token, expires_at: nil)
      expect(token).not_to be_valid
      expect(token.errors[:expires_at]).to include("can't be blank")
    end
  end

  describe 'encryption' do
    let(:token) { create(:nationbuilder_token, user: user) }

    it 'encrypts access_token' do
      raw_value = token.access_token
      encrypted_value = token.read_attribute_before_type_cast(:access_token)
      expect(encrypted_value).not_to eq(raw_value)
    end

    it 'encrypts refresh_token' do
      raw_value = token.refresh_token
      encrypted_value = token.read_attribute_before_type_cast(:refresh_token)
      expect(encrypted_value).not_to eq(raw_value)
    end
  end

  describe 'scopes' do
    let!(:expired_token) do
      create(:nationbuilder_token, user: user, expires_at: 1.hour.ago)
    end
    
    let!(:expiring_soon_token) do
      create(:nationbuilder_token, user: user, expires_at: 3.minutes.from_now)
    end
    
    let!(:valid_token) do
      create(:nationbuilder_token, user: user, expires_at: 1.hour.from_now)
    end

    describe '.expired' do
      it 'returns only expired tokens' do
        expect(described_class.expired).to contain_exactly(expired_token)
      end
    end

    describe '.expiring_soon' do
      it 'returns tokens expiring within buffer time' do
        expect(described_class.expiring_soon(5)).to contain_exactly(expiring_soon_token)
      end
    end

    describe '.valid_for_api' do
      it 'returns tokens that are not expired' do
        expect(described_class.valid_for_api).to contain_exactly(expiring_soon_token, valid_token)
      end
    end

    describe '.needs_refresh' do
      it 'returns tokens that are expired or expiring soon' do
        expect(described_class.needs_refresh(5)).to contain_exactly(expired_token, expiring_soon_token)
      end
    end
  end

  describe '#expired?' do
    it 'returns true when token is expired' do
      token = build(:nationbuilder_token, expires_at: 1.hour.ago)
      expect(token.expired?).to be true
    end

    it 'returns false when token is not expired' do
      token = build(:nationbuilder_token, expires_at: 1.hour.from_now)
      expect(token.expired?).to be false
    end
  end

  describe '#expiring_soon?' do
    it 'returns true when token expires within buffer time' do
      token = build(:nationbuilder_token, expires_at: 3.minutes.from_now)
      expect(token.expiring_soon?(5)).to be true
    end

    it 'returns false when token expires after buffer time' do
      token = build(:nationbuilder_token, expires_at: 10.minutes.from_now)
      expect(token.expiring_soon?(5)).to be false
    end

    it 'uses default buffer of 5 minutes' do
      token = build(:nationbuilder_token, expires_at: 3.minutes.from_now)
      expect(token.expiring_soon?).to be true
    end
  end

  describe '#valid_for_api_use?' do
    it 'returns true when token has access_token and is not expired' do
      token = build(:nationbuilder_token, 
                   access_token: 'token123',
                   expires_at: 1.hour.from_now)
      expect(token.valid_for_api_use?).to be true
    end

    it 'returns false when token is expired' do
      token = build(:nationbuilder_token,
                   access_token: 'token123',
                   expires_at: 1.hour.ago)
      expect(token.valid_for_api_use?).to be false
    end

    it 'returns false when access_token is blank' do
      token = build(:nationbuilder_token,
                   access_token: '',
                   expires_at: 1.hour.from_now)
      expect(token.valid_for_api_use?).to be false
    end
  end

  describe '#needs_refresh?' do
    it 'returns true when token is expired' do
      token = build(:nationbuilder_token, expires_at: 1.hour.ago)
      expect(token.needs_refresh?).to be true
    end

    it 'returns true when token is expiring soon' do
      token = build(:nationbuilder_token, expires_at: 3.minutes.from_now)
      expect(token.needs_refresh?(5)).to be true
    end

    it 'returns false when token is not expiring soon' do
      token = build(:nationbuilder_token, expires_at: 10.minutes.from_now)
      expect(token.needs_refresh?(5)).to be false
    end
  end

  describe '#time_until_expiry' do
    it 'returns time until expiration when not expired' do
      freeze_time do
        token = build(:nationbuilder_token, expires_at: 30.minutes.from_now)
        expect(token.time_until_expiry).to be_within(1.second).of(30.minutes)
      end
    end

    it 'returns 0 when token is expired' do
      token = build(:nationbuilder_token, expires_at: 1.hour.ago)
      expect(token.time_until_expiry).to eq(0)
    end
  end

  describe '#refresh!' do
    let(:token) { create(:nationbuilder_token, user: user) }
    let(:refresh_service) { instance_double(NationbuilderTokenRefreshService) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('NATIONBUILDER_CLIENT_ID').and_return('client_id')
      allow(ENV).to receive(:[]).with('NATIONBUILDER_CLIENT_SECRET').and_return('client_secret')
      allow(NationbuilderTokenRefreshService).to receive(:new).and_return(refresh_service)
    end

    it 'creates refresh service with correct parameters' do
      expect(NationbuilderTokenRefreshService).to receive(:new).with(
        client_id: 'client_id',
        client_secret: 'client_secret'
      )
      allow(refresh_service).to receive(:refresh_token).and_return(true)
      
      token.refresh!
    end

    it 'calls refresh_token on the service' do
      expect(refresh_service).to receive(:refresh_token).with(token).and_return(true)
      token.refresh!
    end

    it 'returns the result from the service' do
      allow(refresh_service).to receive(:refresh_token).and_return(false)
      expect(token.refresh!).to be false
    end
  end

  describe '#update_tokens!' do
    let(:token) { create(:nationbuilder_token, user: user) }

    it 'updates all token fields' do
      freeze_time do
        token.update_tokens!(
          access_token: 'new_access',
          refresh_token: 'new_refresh',
          expires_in: 3600,
          scope: 'read write',
          raw_response: { test: 'data' }
        )

        expect(token.reload.access_token).to eq('new_access')
        expect(token.refresh_token).to eq('new_refresh')
        expect(token.expires_at).to be_within(1.second).of(Time.current + 3600.seconds)
        expect(token.scope).to eq('read write')
        expect(token.raw_response).to eq({ 'test' => 'data' })
      end
    end
  end
end
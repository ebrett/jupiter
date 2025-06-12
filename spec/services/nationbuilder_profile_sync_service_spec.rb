require 'rails_helper'

RSpec.describe NationbuilderProfileSyncService do
  let(:user) { create(:user, :nationbuilder_user) }
  let(:service) { described_class.new(user: user) }
  let(:valid_token) { create(:nationbuilder_token, user: user, expires_at: 1.hour.from_now) }

  describe '#sync_profile_data' do
    context 'when user should not sync' do
      it 'returns false for non-NationBuilder users' do
        user = create(:user, :email_password_user)
        service = described_class.new(user: user)

        expect(service.sync_profile_data).to be(false)
      end

      it 'returns false when user has no tokens' do
        user.nationbuilder_tokens.destroy_all

        expect(service.sync_profile_data).to be(false)
      end
    end

    context 'when sync should proceed' do
      let(:profile_data) do
        {
          id: user.nationbuilder_uid,
          email: user.email_address,
          first_name: 'Updated',
          last_name: 'Name',
          phone: '+1 555-123-4567',
          tags: [ 'member', 'volunteer', 'donor' ],
          raw_data: { city: 'San Francisco' }
        }
      end

      before do
        valid_token
        user_service = instance_double(NationbuilderUserService)
        allow(NationbuilderUserService).to receive(:new).and_return(user_service)
        allow(user_service).to receive(:fetch_user_profile).and_return(profile_data)
      end

      it 'fetches and updates profile data' do
        expect(service.sync_profile_data).to be(true)

        user.reload
        expect(user.nationbuilder_profile_data).to include(
          'tags' => [ 'member', 'volunteer', 'donor' ],
          'phone' => '+1 555-123-4567',
          'last_synced_at' => be_present
        )
      end

      it 'does not overwrite existing name data' do
        user.update!(first_name: 'Existing', last_name: 'User')

        service.sync_profile_data

        user.reload
        expect(user.first_name).to eq('Existing')
        expect(user.last_name).to eq('User')
      end

      it 'fills in blank name data' do
        user.update!(first_name: nil, last_name: nil)

        service.sync_profile_data

        user.reload
        expect(user.first_name).to eq('Updated')
        expect(user.last_name).to eq('Name')
      end

      it 'refreshes token if needed' do
        valid_token.update!(expires_at: 1.minute.from_now)

        # Mock the token retrieval to return our test token
        allow(user.nationbuilder_tokens).to receive(:first).and_return(valid_token)
        allow(valid_token).to receive(:refresh!)
        allow(valid_token).to receive_messages(needs_refresh?: true, valid_for_api_use?: true)

        expect(valid_token).to receive(:refresh!)

        service.sync_profile_data
      end
    end

    context 'when handling errors' do
      before { valid_token }

      it 'returns false on API errors' do
        user_service = instance_double(NationbuilderUserService)
        allow(NationbuilderUserService).to receive(:new).and_return(user_service)
        allow(user_service).to receive(:fetch_user_profile).and_raise(StandardError, 'API Error')

        expect(Rails.logger).to receive(:error).at_least(:once)
        expect(service.sync_profile_data).to be(false)
      end

      it 'returns false on token refresh failures' do
        valid_token.update!(expires_at: 1.minute.ago)
        allow(valid_token).to receive(:refresh!).and_raise(StandardError, 'Token refresh failed')

        expect(Rails.logger).to receive(:error).at_least(:once)
        expect(service.sync_profile_data).to be(false)
      end
    end
  end
end

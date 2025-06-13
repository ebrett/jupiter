require 'rails_helper'

RSpec.describe NationbuilderProfileSyncJob do
  let(:user) { create(:user, :nationbuilder_user) }

  describe '#perform' do
    it 'calls the sync service for the user' do
      sync_service = instance_double(NationbuilderProfileSyncService)
      allow(NationbuilderProfileSyncService).to receive(:new).with(user: user).and_return(sync_service)
      allow(sync_service).to receive(:sync_profile_data).and_return(true)

      expect(sync_service).to receive(:sync_profile_data)

      described_class.new.perform(user.id)
    end

    it 'handles non-existent users gracefully' do
      # The job has discard_on ActiveRecord::RecordNotFound
      # This means it won't raise an error and will just discard the job
      expect { described_class.perform_now(999999) }.not_to raise_error

      # Verify it doesn't call the sync service for non-existent users
      expect(NationbuilderProfileSyncService).not_to receive(:new)
      described_class.perform_now(999999)
    end

    it 'skips sync for non-NationBuilder users' do
      user.update!(nationbuilder_uid: nil)

      expect(NationbuilderProfileSyncService).not_to receive(:new)
      described_class.new.perform(user.id)
    end

    it 'logs success' do
      sync_service = instance_double(NationbuilderProfileSyncService)
      allow(NationbuilderProfileSyncService).to receive(:new).and_return(sync_service)
      allow(sync_service).to receive(:sync_profile_data).and_return(true)

      expect(Rails.logger).to receive(:info).with("Successfully synced NationBuilder profile for user #{user.id}")
      described_class.new.perform(user.id)
    end

    it 'logs failure' do
      sync_service = instance_double(NationbuilderProfileSyncService)
      allow(NationbuilderProfileSyncService).to receive(:new).and_return(sync_service)
      allow(sync_service).to receive(:sync_profile_data).and_return(false)

      expect(Rails.logger).to receive(:warn).with("Failed to sync NationBuilder profile for user #{user.id}")
      described_class.new.perform(user.id)
    end
  end
end

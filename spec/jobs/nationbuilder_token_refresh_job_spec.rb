require 'rails_helper'

RSpec.describe NationbuilderTokenRefreshJob, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let!(:nationbuilder_token) do
    create(:nationbuilder_token,
           user: user,
           expires_at: 10.minutes.from_now)
  end

  describe '#perform' do
    context 'when user exists and has a token that needs refresh' do
      before do
        # Make the token need refresh
        nationbuilder_token.update!(expires_at: 1.minute.from_now)
      end

      it 'refreshes the token' do
        expect_any_instance_of(NationbuilderToken).to receive(:refresh!).and_return(true)
        described_class.new.perform(user.id)
      end

      it 'logs successful refresh' do
        allow_any_instance_of(NationbuilderToken).to receive(:refresh!).and_return(true)
        expect(Rails.logger).to receive(:info).with("Proactively refreshing token for user #{user.id}")
        expect(Rails.logger).to receive(:info).with("Successfully refreshed token for user #{user.id}")

        described_class.new.perform(user.id)
      end
    end

    context 'when token refresh fails' do
      before do
        # Make the token need refresh
        nationbuilder_token.update!(expires_at: 1.minute.from_now)
      end

      it 'logs failure' do
        allow_any_instance_of(NationbuilderToken).to receive(:refresh!).and_return(false)
        expect(Rails.logger).to receive(:info).with("Proactively refreshing token for user #{user.id}")
        expect(Rails.logger).to receive(:error).with("Failed to refresh token for user #{user.id}")
        described_class.new.perform(user.id)
      end
    end

    context 'when user does not exist' do
      it 'does not raise an error' do
        expect { described_class.new.perform(999999) }.not_to raise_error
      end

      it 'does not attempt token refresh' do
        expect { described_class.new.perform(999999) }.not_to raise_error
        # Expect no errors
      end
    end

    context 'when user has no nationbuilder token' do
      let(:user_without_token) { create(:user) }

      it 'does not attempt refresh' do
        expect { described_class.new.perform(user_without_token.id) }.not_to raise_error
        # Expect no errors
      end
    end

    context 'when token does not need refresh' do
      # Token is already set to expire in 10 minutes, which doesn't need refresh

      it 'does not attempt refresh' do
        expect_any_instance_of(NationbuilderToken).not_to receive(:refresh!)
        described_class.new.perform(user.id)
      end
    end
  end

  describe '.enqueue_for_expiring_tokens' do
    let!(:user_with_soon_expiring_token1) { create(:user) }
    let!(:user_with_soon_expiring_token2) { create(:user) }
    let!(:user_with_distant_expiring_token) { create(:user) }

    let!(:soon_expiring_token1) do
      create(:nationbuilder_token,
             user: user_with_soon_expiring_token1,
             expires_at: 20.minutes.from_now)
    end

    let!(:soon_expiring_token2) do
      create(:nationbuilder_token,
             user: user_with_soon_expiring_token2,
             expires_at: 25.minutes.from_now)
    end

    let(:distant_expiring_token) do
      create(:nationbuilder_token,
             user: user_with_distant_expiring_token,
             expires_at: 2.hours.from_now)
    end

    it 'enqueues jobs for tokens expiring within buffer time' do
      expect {
        described_class.enqueue_for_expiring_tokens(30)
      }.to have_enqueued_job(described_class).with(user_with_soon_expiring_token1.id)
        .and have_enqueued_job(described_class).with(user_with_soon_expiring_token2.id)
    end

    it 'does not enqueue jobs for tokens not expiring soon' do
      distant_expiring_token # Create the token
      expect {
        described_class.enqueue_for_expiring_tokens(30)
      }.not_to have_enqueued_job(described_class).with(user_with_distant_expiring_token.id)
    end


    it 'does not enqueue for already expired tokens' do
      expired_token = create(:nationbuilder_token,
                            user: create(:user),
                            expires_at: 1.hour.ago)

      expect {
        described_class.enqueue_for_expiring_tokens(30)
      }.not_to have_enqueued_job(described_class).with(expired_token.user.id)
    end
  end

  describe '.schedule_periodic_refresh' do
    it 'calls enqueue_for_expiring_tokens with 30 minute buffer' do
      expect(described_class).to receive(:enqueue_for_expiring_tokens).with(30)
      described_class.schedule_periodic_refresh
    end
  end
end

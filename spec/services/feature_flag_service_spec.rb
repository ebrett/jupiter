require 'rails_helper'

RSpec.describe FeatureFlagService, type: :service do
  let(:user) { create(:user) }
  let(:role) { create(:role, :submitter) }
  let(:flag) { create(:feature_flag, :enabled, name: 'test_feature') }

  describe '.enabled?' do
    context 'when flag does not exist' do
      it 'returns false' do
        expect(described_class.enabled?('nonexistent_flag', user)).to be false
      end
    end

    context 'when flag is disabled globally' do
      let(:disabled_flag) { create(:feature_flag, :disabled, name: 'disabled_feature') }

      it 'returns false even with user assignment' do
        create(:feature_flag_assignment, feature_flag: disabled_flag, assignable: user)
        expect(described_class.enabled?('disabled_feature', user)).to be false
      end
    end

    context 'when flag is enabled globally' do
      it 'returns false for user without assignment' do
        expect(described_class.enabled?(flag.name, user)).to be false
      end

      it 'returns true for user with direct assignment' do
        create(:feature_flag_assignment, feature_flag: flag, assignable: user)
        expect(described_class.enabled?(flag.name, user)).to be true
      end

      it 'returns true for user with role assignment' do
        user.add_role(role.name)
        create(:feature_flag_assignment, feature_flag: flag, assignable: role)
        expect(described_class.enabled?(flag.name, user)).to be true
      end
    end

    context 'on service errors' do
      before do
        allow(FeatureFlag).to receive(:find_by).and_raise(StandardError, 'Database error')
      end

      it 'fails safely and returns false' do
        expect(described_class.enabled?(flag.name, user)).to be false
      end

      it 'logs the error' do
        expect(Rails.logger).to receive(:error).with(/FeatureFlagService error/)
        described_class.enabled?(flag.name, user)
      end
    end
  end

  describe '.disabled?' do
    it 'returns opposite of enabled?' do
      expect(described_class.disabled?(flag.name, user)).to be true

      create(:feature_flag_assignment, feature_flag: flag, assignable: user)
      expect(described_class.disabled?(flag.name, user)).to be false
    end
  end

  describe '.enable_for_user' do
    it 'creates assignment for user' do
      expect {
        described_class.enable_for_user(flag.name, user)
      }.to change(FeatureFlagAssignment, :count).by(1)

      assignment = FeatureFlagAssignment.last
      expect(assignment.feature_flag).to eq(flag)
      expect(assignment.assignable).to eq(user)
    end

    it 'returns true on success' do
      expect(described_class.enable_for_user(flag.name, user)).to be true
    end

    it 'does not create duplicate assignments' do
      described_class.enable_for_user(flag.name, user)
      expect {
        described_class.enable_for_user(flag.name, user)
      }.not_to change(FeatureFlagAssignment, :count)
    end
  end

  describe '.disable_for_user' do
    before do
      create(:feature_flag_assignment, feature_flag: flag, assignable: user)
    end

    it 'removes assignment for user' do
      expect {
        described_class.disable_for_user(flag.name, user)
      }.to change(FeatureFlagAssignment, :count).by(-1)
    end

    it 'returns true on success' do
      expect(described_class.disable_for_user(flag.name, user)).to be true
    end
  end

  describe '.enable_for_role' do
    it 'creates assignment for role' do
      expect {
        described_class.enable_for_role(flag.name, role.name)
      }.to change(FeatureFlagAssignment, :count).by(1)

      assignment = FeatureFlagAssignment.last
      expect(assignment.feature_flag).to eq(flag)
      expect(assignment.assignable).to eq(role)
    end
  end

  describe '.clear_cache' do
    it 'clears specific flag cache' do
      expect(Rails.cache).to receive(:delete).with("feature_flag_#{flag.name}")
      expect(Rails.cache).to receive(:delete).with("feature_flag_#{flag.name}_assignments")

      described_class.clear_cache(flag.name)
    end

    it 'clears all flag cache when no flag specified' do
      expect(Rails.cache).to receive(:delete_matched).with("feature_flag_*")

      described_class.clear_cache
    end
  end
end

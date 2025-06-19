require 'rails_helper'

RSpec.describe FeatureFlag, type: :model do
  describe 'validations' do
    it 'validates presence of name' do
      flag = build(:feature_flag, name: nil)
      expect(flag).not_to be_valid
      expect(flag.errors[:name]).to include("can't be blank")
    end

    it 'validates presence of description' do
      flag = build(:feature_flag, description: nil)
      expect(flag).not_to be_valid
      expect(flag.errors[:description]).to include("can't be blank")
    end

    it 'validates uniqueness of name' do
      create(:feature_flag, name: 'test_name')
      flag = build(:feature_flag, name: 'test_name')
      expect(flag).not_to be_valid
      expect(flag.errors[:name]).to include("has already been taken")
    end

    it 'validates name format' do
      expect(build(:feature_flag, name: 'valid_name')).to be_valid
      expect(build(:feature_flag, name: 'INVALID_NAME')).not_to be_valid
      expect(build(:feature_flag, name: 'invalid-name')).not_to be_valid
      expect(build(:feature_flag, name: '123invalid')).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to created_by user optionally' do
      flag = build(:feature_flag, created_by: nil)
      expect(flag).to be_valid
    end

    it 'belongs to updated_by user optionally' do
      flag = build(:feature_flag, updated_by: nil)
      expect(flag).to be_valid
    end

    it 'has many feature flag assignments' do
      flag = create(:feature_flag)
      user = create(:user)
      assignment = create(:feature_flag_assignment, feature_flag: flag, assignable: user)

      expect(flag.feature_flag_assignments).to include(assignment)
    end
  end

  describe 'scopes' do
    let!(:enabled_flag) { create(:feature_flag, enabled: true) }
    let!(:disabled_flag) { create(:feature_flag, enabled: false) }

    it 'filters enabled flags' do
      expect(described_class.enabled).to include(enabled_flag)
      expect(described_class.enabled).not_to include(disabled_flag)
    end

    it 'filters disabled flags' do
      expect(described_class.disabled).to include(disabled_flag)
      expect(described_class.disabled).not_to include(enabled_flag)
    end
  end

  describe 'methods' do
    let(:flag) { create(:feature_flag, enabled: false) }

    describe '#enable!' do
      it 'enables the flag' do
        expect { flag.enable! }.to change { flag.reload.enabled? }.from(false).to(true)
      end
    end

    describe '#disable!' do
      let(:enabled_flag) { create(:feature_flag, enabled: true) }

      it 'disables the flag' do
        expect { enabled_flag.disable! }.to change { enabled_flag.reload.enabled? }.from(true).to(false)
      end
    end

    describe '#toggle!' do
      it 'toggles enabled state' do
        expect { flag.toggle! }.to change { flag.reload.enabled? }.from(false).to(true)
        expect { flag.toggle! }.to change { flag.reload.enabled? }.from(true).to(false)
      end
    end
  end
end

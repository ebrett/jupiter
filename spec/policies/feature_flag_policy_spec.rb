require 'rails_helper'

RSpec.describe FeatureFlagPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :with_system_administrator_role) }
  let(:non_admin_user) { create(:user, :with_submitter_role) }
  let(:feature_flag) { create(:feature_flag) }

  permissions :index?, :show?, :edit?, :update?, :toggle?, :clear_cache? do
    it "grants access to admin users" do
      expect(subject).to permit(admin_user, feature_flag)
    end

    it "denies access to non-admin users" do
      expect(subject).not_to permit(non_admin_user, feature_flag)
    end

    it "denies access to nil user" do
      expect(subject).not_to permit(nil, feature_flag)
    end
  end

  permissions :new?, :create?, :destroy? do
    it "grants access to system administrators" do
      expect(subject).to permit(admin_user, feature_flag)
    end

    it "denies access to non-admin users" do
      expect(subject).not_to permit(non_admin_user, feature_flag)
    end

    it "denies access to nil user" do
      expect(subject).not_to permit(nil, feature_flag)
    end

    context "with admin user without system_administrator role" do
      let(:treasury_admin) { create(:user, :with_treasury_team_admin_role) }

      it "denies access for destructive operations" do
        expect(subject).not_to permit(treasury_admin, feature_flag)
      end
    end
  end

  describe "Scope" do
    let!(:feature_flag1) { create(:feature_flag, name: 'test_flag_1') }
    let!(:feature_flag2) { create(:feature_flag, name: 'test_flag_2') }

    context "when user is admin" do
      it "returns all feature flags" do
        resolved_scope = described_class::Scope.new(admin_user, FeatureFlag).resolve
        expect(resolved_scope).to include(feature_flag1, feature_flag2)
      end
    end

    context "when user is not admin" do
      it "returns no feature flags" do
        resolved_scope = described_class::Scope.new(non_admin_user, FeatureFlag).resolve
        expect(resolved_scope).to be_empty
      end
    end

    context "when user is nil" do
      it "returns no feature flags" do
        resolved_scope = described_class::Scope.new(nil, FeatureFlag).resolve
        expect(resolved_scope).to be_empty
      end
    end
  end
end

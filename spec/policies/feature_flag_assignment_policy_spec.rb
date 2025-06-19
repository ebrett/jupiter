require 'rails_helper'

RSpec.describe FeatureFlagAssignmentPolicy, type: :policy do
  subject { described_class }

  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :with_system_administrator_role) }
  let(:non_admin_user) { create(:user, :with_submitter_role) }
  let(:feature_flag) { create(:feature_flag) }
  let(:assignment) { create(:feature_flag_assignment, feature_flag: feature_flag, assignable: user) }

  permissions :create?, :destroy? do
    it "grants access to admin users" do
      expect(subject).to permit(admin_user, assignment)
    end

    it "denies access to non-admin users" do
      expect(subject).not_to permit(non_admin_user, assignment)
    end

    it "denies access to nil user" do
      expect(subject).not_to permit(nil, assignment)
    end
  end

  describe "Scope" do
    let!(:assignment1) { create(:feature_flag_assignment, feature_flag: feature_flag, assignable: user) }
    let!(:assignment2) { create(:feature_flag_assignment, feature_flag: feature_flag, assignable: create(:user)) }

    context "when user is admin" do
      it "returns all assignments" do
        resolved_scope = described_class::Scope.new(admin_user, FeatureFlagAssignment).resolve
        expect(resolved_scope).to include(assignment1, assignment2)
      end
    end

    context "when user is not admin" do
      it "returns no assignments" do
        resolved_scope = described_class::Scope.new(non_admin_user, FeatureFlagAssignment).resolve
        expect(resolved_scope).to be_empty
      end
    end

    context "when user is nil" do
      it "returns no assignments" do
        resolved_scope = described_class::Scope.new(nil, FeatureFlagAssignment).resolve
        expect(resolved_scope).to be_empty
      end
    end
  end
end

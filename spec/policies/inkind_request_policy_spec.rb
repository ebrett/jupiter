require 'rails_helper'

RSpec.describe InkindRequestPolicy, type: :policy do
  let(:inkind_request) { build(:inkind_request) }

  context 'for a user without any roles' do
    let(:user) { create(:user) }
    let(:policy) { described_class.new(user, inkind_request) }

    it 'denies all actions' do
      expect(policy.index?).to be_falsey
      expect(policy.show?).to be_falsey
      expect(policy.new?).to be_falsey
      expect(policy.create?).to be_falsey
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey
      expect(policy.export?).to be_falsey
    end
  end

  context 'for a user with submitter role' do
    let(:user) { create(:user) }
    let(:policy) { described_class.new(user, inkind_request) }
    
    before { user.add_role('submitter') }

    it 'allows new and create' do
      expect(policy.index?).to be_falsey
      expect(policy.show?).to be_falsey
      expect(policy.new?).to be_truthy
      expect(policy.create?).to be_truthy
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey
      expect(policy.export?).to be_falsey
    end
  end

  context 'for an admin user' do
    let(:user) { create(:user) }
    let(:policy) { described_class.new(user, inkind_request) }
    
    before { user.add_role('system_administrator') }

    it 'allows admin actions' do
      expect(policy.index?).to be_truthy
      expect(policy.show?).to be_truthy
      expect(policy.new?).to be_truthy
      expect(policy.create?).to be_truthy
      expect(policy.edit?).to be_falsey
      expect(policy.update?).to be_falsey
      expect(policy.destroy?).to be_falsey
      expect(policy.export?).to be_truthy
    end
  end

  describe 'Scope' do
    let(:admin_user) { create(:user) }
    let(:regular_user) { create(:user) }
    
    before { admin_user.add_role('system_administrator') }

    it 'returns all records for admin users' do
      scope = Pundit.policy_scope(admin_user, InkindRequest)
      expect(scope).to eq(InkindRequest.all)
    end

    it 'returns no records for non-admin users' do
      scope = Pundit.policy_scope(regular_user, InkindRequest)
      expect(scope).to eq(InkindRequest.none)
    end
  end
end
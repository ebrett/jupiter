require 'rails_helper'

RSpec.describe InkindRequestPolicy, type: :policy do
  let(:inkind_request) { build(:inkind_request) }

  context 'for a user without any roles' do
    let(:user) { create(:user) }
    let(:policy) { described_class.new(user, inkind_request) }

    it 'denies all actions' do
      expect(policy).not_to be_index
      expect(policy).not_to be_show
      expect(policy).not_to be_new
      expect(policy).not_to be_create
      expect(policy).not_to be_edit
      expect(policy).not_to be_update
      expect(policy).not_to be_destroy
      expect(policy).not_to be_export
    end
  end

  context 'for a user with submitter role' do
    let(:user) { create(:user) }
    let(:policy) { described_class.new(user, inkind_request) }

    before { user.add_role('submitter') }

    it 'allows new and create' do
      expect(policy).not_to be_index
      expect(policy).not_to be_show
      expect(policy).to be_new
      expect(policy).to be_create
      expect(policy).not_to be_edit
      expect(policy).not_to be_update
      expect(policy).not_to be_destroy
      expect(policy).not_to be_export
    end
  end

  context 'for an admin user' do
    let(:user) { create(:user) }
    let(:policy) { described_class.new(user, inkind_request) }

    before { user.add_role('system_administrator') }

    it 'allows admin actions' do
      expect(policy).to be_index
      expect(policy).to be_show
      expect(policy).to be_new
      expect(policy).to be_create
      expect(policy).not_to be_edit
      expect(policy).not_to be_update
      expect(policy).not_to be_destroy
      expect(policy).to be_export
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

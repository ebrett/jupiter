require 'rails_helper'

RSpec.describe RolePolicy, type: :policy do
  subject { described_class }

  let(:super_admin) { create(:user) }
  let(:treasury_admin) { create(:user) }
  let(:submitter) { create(:user) }
  let(:role_record) { Role.find_by(name: 'viewer') }

  before do
    super_admin.add_role(:super_admin)
    treasury_admin.add_role(:treasury_team_admin)
    submitter.add_role(:submitter)
  end

  permissions :index?, :show? do
    it 'grants access to admin users' do
      expect(subject).to permit(super_admin, role_record)
      expect(subject).to permit(treasury_admin, role_record)
    end

    it 'denies access to non-admin users' do
      expect(subject).not_to permit(submitter, role_record)
    end
  end

  permissions :create?, :update?, :assign_to_user?, :remove_from_user? do
    it 'grants access to super admin only' do
      expect(subject).to permit(super_admin, role_record)
    end

    it 'denies access to other admin types' do
      expect(subject).not_to permit(treasury_admin, role_record)
    end

    it 'denies access to non-admin users' do
      expect(subject).not_to permit(submitter, role_record)
    end
  end

  permissions :destroy? do
    it 'denies access to all users' do
      expect(subject).not_to permit(super_admin, role_record)
      expect(subject).not_to permit(treasury_admin, role_record)
      expect(subject).not_to permit(submitter, role_record)
    end
  end

  describe RolePolicy::Scope do
    before do
      role_record # ensure role exists
    end

    it 'returns all roles for admin users' do
      resolved = Pundit.policy_scope(super_admin, Role)
      expect(resolved).to include(role_record)
    end

    it 'returns no roles for non-admin users' do
      resolved = Pundit.policy_scope(submitter, Role)
      expect(resolved).to be_empty
    end
  end
end

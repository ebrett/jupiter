require 'rails_helper'

RSpec.describe RolePolicy, type: :policy do
  subject { described_class }

  let(:system_administrator) { create(:user) }
  let(:treasury_admin) { create(:user) }
  let(:submitter) { create(:user) }
  let(:role_record) { Role.find_by(name: 'viewer') }

  before do
    system_administrator.add_role(:system_administrator)
    treasury_admin.add_role(:treasury_team_admin)
    submitter.add_role(:submitter)
  end

  permissions :index?, :show? do
    it 'grants access to system administrator only' do
      expect(subject).to permit(system_administrator, role_record)
      expect(subject).not_to permit(treasury_admin, role_record)
    end

    it 'denies access to non-admin users' do
      expect(subject).not_to permit(submitter, role_record)
    end
  end

  permissions :create?, :update?, :assign_to_user?, :remove_from_user? do
    it 'grants access to system administrator only' do
      expect(subject).to permit(system_administrator, role_record)
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
      expect(subject).not_to permit(system_administrator, role_record)
      expect(subject).not_to permit(treasury_admin, role_record)
      expect(subject).not_to permit(submitter, role_record)
    end
  end

  describe RolePolicy::Scope do
    before do
      role_record # ensure role exists
    end

    it 'returns all roles for system administrator' do
      resolved = Pundit.policy_scope(system_administrator, Role)
      expect(resolved).to include(role_record)
    end

    it 'returns no roles for non-admin users' do
      resolved = Pundit.policy_scope(submitter, Role)
      expect(resolved).to be_empty
    end
  end
end

require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:system_administrator) { create(:user) }
  let(:treasury_admin) { create(:user) }
  let(:chapter_admin) { create(:user) }
  let(:submitter) { create(:user) }
  let(:viewer) { create(:user) }
  let(:target_user) { create(:user) }

  before do
    system_administrator.add_role(:system_administrator)
    treasury_admin.add_role(:treasury_team_admin)
    chapter_admin.add_role(:country_chapter_admin)
    submitter.add_role(:submitter)
    viewer.add_role(:viewer)
  end

  permissions :index? do
    it 'grants access to system administrator only' do
      expect(subject).to permit(system_administrator, User)
      expect(subject).not_to permit(treasury_admin, User)
      expect(subject).not_to permit(chapter_admin, User)
    end

    it 'denies access to non-admin users' do
      expect(subject).not_to permit(submitter, User)
      expect(subject).not_to permit(viewer, User)
    end
  end

  permissions :show? do
    context 'when user is a system administrator' do
      it 'grants show access to any user record' do
        expect(subject).to permit(system_administrator, target_user)
      end
    end

    context 'when user is not a system administrator' do
      it 'grants show access to own record only' do
        expect(subject).to permit(submitter, submitter)
        expect(subject).not_to permit(submitter, target_user)
        expect(subject).not_to permit(treasury_admin, target_user)
      end
    end
  end

  permissions :create? do
    it 'grants create access to system administrator only' do
      expect(subject).to permit(system_administrator, User)
    end

    it 'denies create access to other users' do
      expect(subject).not_to permit(treasury_admin, User)
      expect(subject).not_to permit(chapter_admin, User)
      expect(subject).not_to permit(submitter, User)
    end
  end

  permissions :update? do
    context 'when user is a system administrator' do
      it 'can update any user except self or other system administrators' do
        expect(subject).to permit(system_administrator, target_user)
        expect(subject).not_to permit(system_administrator, system_administrator)
        other_system_administrator = create(:user)
        other_system_administrator.add_role(:system_administrator)
        expect(subject).not_to permit(system_administrator, other_system_administrator)
      end
    end

    context 'when user is not a system administrator' do
      it 'cannot update any user' do
        expect(subject).not_to permit(treasury_admin, target_user)
        expect(subject).not_to permit(submitter, target_user)
      end
    end
  end

  permissions :destroy? do
    context 'when user is a system administrator' do
      it 'can destroy only non-system-administrator users' do
        expect(subject).to permit(system_administrator, target_user)
        expect(subject).not_to permit(system_administrator, system_administrator)
        other_system_administrator = create(:user)
        other_system_administrator.add_role(:system_administrator)
        expect(subject).not_to permit(system_administrator, other_system_administrator)
      end
    end

    context 'when user is not a system administrator' do
      it 'cannot destroy any user' do
        expect(subject).not_to permit(treasury_admin, target_user)
        expect(subject).not_to permit(submitter, target_user)
      end
    end
  end

  permissions :manage_roles?, :assign_role?, :remove_role?, :bulk_update? do
    context 'when checking role management permissions' do
      it 'allows only system administrator to manage roles' do
        expect(subject).to permit(system_administrator, target_user)
        expect(subject).not_to permit(treasury_admin, target_user)
        expect(subject).not_to permit(submitter, target_user)
      end
    end
  end

  describe UserPolicy::Scope do
    let(:all_users) { [ system_administrator, treasury_admin, chapter_admin, submitter, viewer ] }

    before do
      all_users # ensure users are created
    end

    it 'returns all users for system administrator' do
      resolved = Pundit.policy_scope(system_administrator, User)
      expect(resolved).to include(*all_users)
    end

    it 'returns only own record for non-admin users' do
      resolved = Pundit.policy_scope(submitter, User)
      expect(resolved).to eq([ submitter ])
    end
  end
end

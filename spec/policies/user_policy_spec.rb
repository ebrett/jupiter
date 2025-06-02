require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let(:super_admin) { create(:user) }
  let(:treasury_admin) { create(:user) }
  let(:chapter_admin) { create(:user) }
  let(:submitter) { create(:user) }
  let(:viewer) { create(:user) }
  let(:target_user) { create(:user) }

  before do
    super_admin.add_role(:super_admin)
    treasury_admin.add_role(:treasury_team_admin)
    chapter_admin.add_role(:country_chapter_admin)
    submitter.add_role(:submitter)
    viewer.add_role(:viewer)
  end

  permissions :index? do
    it 'grants access to admin users' do
      expect(subject).to permit(super_admin, User)
      expect(subject).to permit(treasury_admin, User)
      expect(subject).to permit(chapter_admin, User)
    end

    it 'denies access to non-admin users' do
      expect(subject).not_to permit(submitter, User)
      expect(subject).not_to permit(viewer, User)
    end
  end

  permissions :show? do
    context 'when user is an admin' do
      it 'grants show access to any user record' do
        expect(subject).to permit(super_admin, target_user)
        expect(subject).to permit(treasury_admin, target_user)
      end
    end

    context 'when user is not an admin' do
      it 'grants show access to own record only' do
        expect(subject).to permit(submitter, submitter)
        expect(subject).not_to permit(submitter, target_user)
      end
    end
  end

  permissions :create? do
    it 'grants create access to super admin only' do
      expect(subject).to permit(super_admin, User)
    end

    it 'denies create access to other admin types' do
      expect(subject).not_to permit(treasury_admin, User)
      expect(subject).not_to permit(chapter_admin, User)
    end
  end

  permissions :update? do
    context 'when user is a super admin' do
      it 'can update any user' do
        expect(subject).to permit(super_admin, target_user)
      end
    end

    context 'when user is a non-super admin' do
      it 'can update non-super-admin users only' do
        expect(subject).to permit(treasury_admin, target_user)
        expect(subject).not_to permit(treasury_admin, super_admin)
      end
    end

    context 'when user is not an admin' do
      it 'cannot update any user' do
        expect(subject).not_to permit(submitter, target_user)
      end
    end
  end

  permissions :destroy? do
    context 'when user is a super admin' do
      it 'can destroy only non-super-admin users' do
        # Can destroy regular users
        expect(subject).to permit(super_admin, target_user)
        # Cannot destroy self
        expect(subject).not_to permit(super_admin, super_admin)
        # Cannot destroy other super admins
        other_super_admin = create(:user)
        other_super_admin.add_role(:super_admin)
        expect(subject).not_to permit(super_admin, other_super_admin)
      end
    end

    context 'when user is a non-super admin' do
      it 'cannot destroy any user' do
        expect(subject).not_to permit(treasury_admin, target_user)
      end
    end
  end

  permissions :manage_roles?, :assign_role?, :remove_role?, :bulk_update? do
    context 'when checking role management permissions' do
      it 'allows only super admin to manage roles' do
        # Super admin can manage roles
        expect(subject).to permit(super_admin, target_user)
        # Other users cannot manage roles
        expect(subject).not_to permit(treasury_admin, target_user)
        expect(subject).not_to permit(submitter, target_user)
      end
    end
  end

  describe UserPolicy::Scope do
    let(:all_users) { [ super_admin, treasury_admin, chapter_admin, submitter, viewer ] }

    before do
      all_users # ensure users are created
    end

    it 'returns all users for super admin' do
      resolved = Pundit.policy_scope(super_admin, User)
      expect(resolved).to include(*all_users)
    end

    it 'returns non-super-admin users for regular admins' do
      resolved = Pundit.policy_scope(treasury_admin, User)
      expect(resolved).to include(treasury_admin, chapter_admin, submitter, viewer)
      expect(resolved).not_to include(super_admin)
    end

    it 'returns only own record for non-admin users' do
      resolved = Pundit.policy_scope(submitter, User)
      expect(resolved).to eq([ submitter ])
    end
  end
end

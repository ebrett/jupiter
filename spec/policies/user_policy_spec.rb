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

  describe '#index?' do
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

  describe '#show?' do
    it 'grants access to admin users' do
      expect(subject).to permit(super_admin, target_user)
      expect(subject).to permit(treasury_admin, target_user)
    end

    it 'grants access to own record' do
      expect(subject).to permit(submitter, submitter)
    end

    it 'denies access to other users records' do
      expect(subject).not_to permit(submitter, target_user)
    end
  end

  describe '#create?' do
    it 'grants access to super admin only' do
      expect(subject).to permit(super_admin, User)
    end

    it 'denies access to other admin types' do
      expect(subject).not_to permit(treasury_admin, User)
      expect(subject).not_to permit(chapter_admin, User)
    end
  end

  describe '#update?' do
    it 'grants access to super admin for any user' do
      expect(subject).to permit(super_admin, target_user)
    end

    it 'grants access to admin for non-super-admin users' do
      expect(subject).to permit(treasury_admin, target_user)
    end

    it 'denies access to admin for super admin users' do
      expect(subject).not_to permit(treasury_admin, super_admin)
    end

    it 'denies access to non-admin users' do
      expect(subject).not_to permit(submitter, target_user)
    end
  end

  describe '#destroy?' do
    it 'grants access to super admin for non-super-admin users' do
      expect(subject).to permit(super_admin, target_user)
    end

    it 'denies access to super admin for their own record' do
      expect(subject).not_to permit(super_admin, super_admin)
    end

    it 'denies access to super admin for other super admin users' do
      other_super_admin = create(:user)
      other_super_admin.add_role(:super_admin)
      expect(subject).not_to permit(super_admin, other_super_admin)
    end

    it 'denies access to other admin types' do
      expect(subject).not_to permit(treasury_admin, target_user)
    end
  end

  [:manage_roles?, :assign_role?, :remove_role?, :bulk_update?].each do |permission|
    describe "##{permission}" do
      it 'grants access to super admin only' do
        expect(subject).to permit(super_admin, target_user)
      end

      it 'denies access to other users' do
        expect(subject).not_to permit(treasury_admin, target_user)
        expect(subject).not_to permit(submitter, target_user)
      end
    end
  end

  describe UserPolicy::Scope do
    let(:all_users) { [super_admin, treasury_admin, chapter_admin, submitter, viewer] }

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
      expect(resolved).to eq([submitter])
    end
  end
end
require 'rails_helper'

RSpec.describe AdminPolicy, type: :policy do
  subject { described_class }

  let(:super_admin) { create(:user) }
  let(:treasury_admin) { create(:user) }
  let(:chapter_admin) { create(:user) }
  let(:submitter) { create(:user) }
  let(:admin_record) { double('admin_record') }

  before do
    super_admin.add_role(:super_admin)
    treasury_admin.add_role(:treasury_team_admin)
    chapter_admin.add_role(:country_chapter_admin)
    submitter.add_role(:submitter)
  end

  permissions :index? do
    it 'grants access to admin users' do
      expect(subject).to permit(super_admin, admin_record)
      expect(subject).to permit(treasury_admin, admin_record)
      expect(subject).to permit(chapter_admin, admin_record)
    end

    it 'denies access to non-admin users' do
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  permissions :oauth_status? do
    it 'grants access to admin users' do
      expect(subject).to permit(super_admin, admin_record)
      expect(subject).to permit(treasury_admin, admin_record)
      expect(subject).to permit(chapter_admin, admin_record)
    end

    it 'denies access to non-admin users' do
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  permissions :system_health? do
    it 'grants access to super admin and treasury admin' do
      expect(subject).to permit(super_admin, admin_record)
      expect(subject).to permit(treasury_admin, admin_record)
    end

    it 'denies access to chapter admin and regular users' do
      expect(subject).not_to permit(chapter_admin, admin_record)
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  permissions :export_oauth_data? do
    it 'grants access to super admin and treasury admin' do
      expect(subject).to permit(super_admin, admin_record)
      expect(subject).to permit(treasury_admin, admin_record)
    end

    it 'denies access to chapter admin and regular users' do
      expect(subject).not_to permit(chapter_admin, admin_record)
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  permissions :view_sensitive_data? do
    it 'grants access to super admin and treasury admin' do
      expect(subject).to permit(super_admin, admin_record)
      expect(subject).to permit(treasury_admin, admin_record)
    end

    it 'denies access to chapter admin and regular users' do
      expect(subject).not_to permit(chapter_admin, admin_record)
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  permissions :user_management? do
    it 'grants access to super admin only' do
      expect(subject).to permit(super_admin, admin_record)
    end

    it 'denies access to all other users' do
      expect(subject).not_to permit(treasury_admin, admin_record)
      expect(subject).not_to permit(chapter_admin, admin_record)
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  permissions :role_management? do
    it 'grants access to super admin only' do
      expect(subject).to permit(super_admin, admin_record)
    end

    it 'denies access to all other users' do
      expect(subject).not_to permit(treasury_admin, admin_record)
      expect(subject).not_to permit(chapter_admin, admin_record)
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  permissions :system_configuration? do
    it 'grants access to super admin only' do
      expect(subject).to permit(super_admin, admin_record)
    end

    it 'denies access to all other users' do
      expect(subject).not_to permit(treasury_admin, admin_record)
      expect(subject).not_to permit(chapter_admin, admin_record)
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  permissions :bulk_operations? do
    it 'grants access to super admin only' do
      expect(subject).to permit(super_admin, admin_record)
    end

    it 'denies access to all other users' do
      expect(subject).not_to permit(treasury_admin, admin_record)
      expect(subject).not_to permit(chapter_admin, admin_record)
      expect(subject).not_to permit(submitter, admin_record)
    end
  end

  describe AdminPolicy::Scope do
    let(:scope) { double('scope') }
    let(:all_result) { double('all_result') }
    let(:filtered_result) { double('filtered_result') }
    let(:chapter_result) { double('chapter_result') }
    let(:none_result) { double('none_result') }

    before do
      allow(scope).to receive(:where).with(sensitive: false).and_return(filtered_result)
      allow(scope).to receive(:where).with(chapter_accessible: true).and_return(chapter_result)
      allow(scope).to receive_messages(all: all_result, none: none_result)
    end

    it 'returns all records for super admin' do
      policy_scope = described_class.new(super_admin, scope)
      result = policy_scope.resolve
      expect(result).to eq(all_result)
    end

    it 'returns filtered records for treasury admin' do
      policy_scope = described_class.new(treasury_admin, scope)
      result = policy_scope.resolve
      expect(result).to eq(filtered_result)
    end

    it 'returns chapter accessible records for chapter admin' do
      policy_scope = described_class.new(chapter_admin, scope)
      result = policy_scope.resolve
      expect(result).to eq(chapter_result)
    end

    it 'returns no records for non-admin users' do
      policy_scope = described_class.new(submitter, scope)
      result = policy_scope.resolve
      expect(result).to eq(none_result)
    end
  end
end

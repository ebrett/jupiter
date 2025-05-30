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

  [:index?, :oauth_status?].each do |permission|
    describe "##{permission}" do
      it 'grants access to admin users' do
        expect(subject).to permit(super_admin, admin_record)
        expect(subject).to permit(treasury_admin, admin_record)
        expect(subject).to permit(chapter_admin, admin_record)
      end

      it 'denies access to non-admin users' do
        expect(subject).not_to permit(submitter, admin_record)
      end
    end
  end

  [:system_health?, :export_oauth_data?, :view_sensitive_data?].each do |permission|
    describe "##{permission}" do
      it 'grants access to super admin and treasury admin' do
        expect(subject).to permit(super_admin, admin_record)
        expect(subject).to permit(treasury_admin, admin_record)
      end

      it 'denies access to chapter admin and regular users' do
        expect(subject).not_to permit(chapter_admin, admin_record)
        expect(subject).not_to permit(submitter, admin_record)
      end
    end
  end

  [:user_management?, :role_management?, :system_configuration?, :bulk_operations?].each do |permission|
    describe "##{permission}" do
      it 'grants access to super admin only' do
        expect(subject).to permit(super_admin, admin_record)
      end

      it 'denies access to all other users' do
        expect(subject).not_to permit(treasury_admin, admin_record)
        expect(subject).not_to permit(chapter_admin, admin_record)
        expect(subject).not_to permit(submitter, admin_record)
      end
    end
  end

  describe AdminPolicy::Scope do
    let(:scope) { double('scope') }

    it 'returns all records for super admin' do
      policy_scope = described_class::Scope.new(super_admin, scope)
      expect(scope).to receive(:all)
      policy_scope.resolve
    end

    it 'returns filtered records for treasury admin' do
      policy_scope = described_class::Scope.new(treasury_admin, scope)
      expect(scope).to receive(:where).with(sensitive: false)
      policy_scope.resolve
    end

    it 'returns chapter accessible records for chapter admin' do
      policy_scope = described_class::Scope.new(chapter_admin, scope)
      expect(scope).to receive(:where).with(chapter_accessible: true)
      policy_scope.resolve
    end

    it 'returns no records for non-admin users' do
      policy_scope = described_class::Scope.new(submitter, scope)
      expect(scope).to receive(:none)
      policy_scope.resolve
    end
  end
end
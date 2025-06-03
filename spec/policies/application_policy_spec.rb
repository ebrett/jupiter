require 'rails_helper'

RSpec.describe ApplicationPolicy, type: :policy do
  let(:user) { create(:user) }
  let(:record) { double('record') }

  describe 'basic permissions' do
    [ :index?, :show?, :create?, :update? ].each do |permission|
      describe "##{permission}" do
        subject { described_class.new(user, record) }

        it 'grants access to authenticated users' do
          expect(subject.public_send(permission)).to be_truthy
        end

        context 'when user is nil' do
          subject { described_class.new(nil, record) }

          it 'denies access to unauthenticated users' do
            expect(subject.public_send(permission)).to be_falsy
          end
        end
      end
    end
  end

  describe '#destroy?' do
    context 'when user is admin' do
      subject { described_class.new(admin_user, record) }

      let(:admin_user) { create(:user) }

      before do
        admin_user.add_role(:super_admin)
      end

      it 'grants access to admin users' do
        expect(subject).to be_destroy
      end
    end

    context 'when user is not admin' do
      subject { described_class.new(regular_user, record) }

      let(:regular_user) { create(:user) }

      before do
        regular_user.add_role(:submitter)
      end

      it 'denies access to non-admin users' do
        expect(subject).not_to be_destroy
      end
    end

    context 'when user is nil' do
      subject { described_class.new(nil, record) }

      it 'denies access to unauthenticated users' do
        expect(subject).not_to be_destroy
      end
    end
  end

  describe 'helper methods' do
    let(:policy) { described_class.new(user, record) }

    describe '#admin?' do
      it 'returns true for super admin' do
        user.add_role(:super_admin)
        expect(policy.send(:admin?)).to be true
      end

      it 'returns true for treasury admin' do
        user.add_role(:treasury_team_admin)
        expect(policy.send(:admin?)).to be true
      end

      it 'returns true for chapter admin' do
        user.add_role(:country_chapter_admin)
        expect(policy.send(:admin?)).to be true
      end

      it 'returns false for non-admin roles' do
        user.add_role(:submitter)
        expect(policy.send(:admin?)).to be false
      end
    end

    describe '#super_admin?' do
      it 'returns true for super admin' do
        user.add_role(:super_admin)
        expect(policy.send(:super_admin?)).to be true
      end

      it 'returns false for other roles' do
        user.add_role(:treasury_team_admin)
        expect(policy.send(:super_admin?)).to be false
      end
    end
  end

  describe ApplicationPolicy::Scope do
    let(:scope) { double('scope') }
    let(:policy_scope) { described_class.new(user, scope) }

    describe '#resolve' do
      it 'returns all records for authenticated users' do
        expect(scope).to receive(:all)
        policy_scope.resolve
      end

      context 'when user is nil' do
        let(:policy_scope_nil) { described_class.new(nil, scope) }

        it 'returns no records for unauthenticated users' do
          expect(scope).to receive(:none)
          policy_scope_nil.resolve
        end
      end
    end
  end
end

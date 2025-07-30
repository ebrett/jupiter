require 'rails_helper'

RSpec.describe ReimbursementRequestPolicy, type: :policy do
  subject(:policy) { described_class.new(user, reimbursement_request) }

  let(:reimbursement_request) { create(:reimbursement_request, user: request_owner) }
  let(:request_owner) { create(:user) }

  describe 'Scope' do
    subject(:scope) { described_class::Scope.new(user, ReimbursementRequest.all).resolve }

    context 'when user is not present' do
      let(:user) { nil }
      let!(:any_request) { create(:reimbursement_request) }

      it 'returns empty scope' do
        expect(scope).to be_empty
      end
    end

    context 'when user is a regular member' do
      let(:user) { create(:user) }
      let!(:own_request) { create(:reimbursement_request, user: user) }
      let!(:other_request) { create(:reimbursement_request) }

      it 'returns only their own requests' do
        expect(scope).to contain_exactly(own_request)
        expect(scope).not_to include(other_request)
      end
    end

    context 'when user is treasury admin' do
      let(:user) { create(:user, :treasury_admin) }
      let!(:own_request) { create(:reimbursement_request, user: user) }
      let!(:other_request) { create(:reimbursement_request) }

      it 'returns all requests' do
        expect(scope).to contain_exactly(own_request, other_request)
      end
    end

    context 'when user is system administrator' do
      let(:user) { create(:user, :system_administrator) }
      let!(:own_request) { create(:reimbursement_request, user: user) }
      let!(:other_request) { create(:reimbursement_request) }

      it 'returns all requests' do
        expect(scope).to contain_exactly(own_request, other_request)
      end
    end

    context 'when user is chapter admin' do
      let(:user) { create(:user, :chapter_admin) }
      let!(:own_request) { create(:reimbursement_request, user: user) }
      let!(:other_request) { create(:reimbursement_request) }

      it 'returns all requests' do
        expect(scope).to contain_exactly(own_request, other_request)
      end
    end
  end

  describe '#index?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_index }
    end

    context 'when user is present' do
      let(:user) { create(:user) }

      it { is_expected.to be_index }
    end
  end

  describe '#show?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_show }
    end

    context 'when user owns the request' do
      let(:user) { request_owner }

      it { is_expected.to be_show }
    end

    context 'when user does not own the request' do
      let(:user) { create(:user) }

      it { is_expected.not_to be_show }
    end

    context 'when user is treasury admin' do
      let(:user) { create(:user, :treasury_admin) }

      it { is_expected.to be_show }
    end

    context 'when user is system administrator' do
      let(:user) { create(:user, :system_administrator) }

      it { is_expected.to be_show }
    end

    context 'when user is chapter admin' do
      let(:user) { create(:user, :chapter_admin) }

      it { is_expected.to be_show }
    end
  end

  describe '#create?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_create }
    end

    context 'when user has submitter role' do
      let(:user) { create(:user, :submitter) }

      it { is_expected.to be_create }
    end

    context 'when user is admin' do
      let(:user) { create(:user, :treasury_admin) }

      it { is_expected.to be_create }
    end

    context 'when user has no submitter role' do
      let(:user) { create(:user, :viewer) }

      it { is_expected.not_to be_create }
    end
  end

  describe '#new?' do
    it 'delegates to create?' do
      user = create(:user, :submitter)
      policy = described_class.new(user, reimbursement_request)
      expect(policy.new?).to eq(policy.create?)
    end
  end

  describe '#update?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_update }
    end

    context 'when user owns the request and it is in draft status' do
      let(:user) { request_owner }
      let(:reimbursement_request) { create(:reimbursement_request, user: request_owner, status: 'draft') }

      it { is_expected.to be_update }
    end

    context 'when user owns the request but it is submitted' do
      let(:user) { request_owner }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted, user: request_owner) }

      it { is_expected.not_to be_update }
    end

    context 'when user owns the request but it is approved' do
      let(:user) { request_owner }
      let(:reimbursement_request) { create(:reimbursement_request, :approved, user: request_owner) }

      it { is_expected.not_to be_update }
    end

    context 'when user does not own the request' do
      let(:user) { create(:user) }
      let(:reimbursement_request) { create(:reimbursement_request, status: 'draft') }

      it { is_expected.not_to be_update }
    end

    context 'when user is treasury admin' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted) }

      it { is_expected.to be_update }
    end
  end

  describe '#edit?' do
    it 'delegates to update?' do
      user = create(:user)
      policy = described_class.new(user, reimbursement_request)
      expect(policy.edit?).to eq(policy.update?)
    end
  end

  describe '#destroy?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_destroy }
    end

    context 'when user owns the request and it is in draft status' do
      let(:user) { request_owner }
      let(:reimbursement_request) { create(:reimbursement_request, user: request_owner, status: 'draft') }

      it { is_expected.to be_destroy }
    end

    context 'when user owns the request but it is submitted' do
      let(:user) { request_owner }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted, user: request_owner) }

      it { is_expected.not_to be_destroy }
    end

    context 'when user does not own the request' do
      let(:user) { create(:user) }
      let(:reimbursement_request) { create(:reimbursement_request, status: 'draft') }

      it { is_expected.not_to be_destroy }
    end

    context 'when user is system administrator' do
      let(:user) { create(:user, :system_administrator) }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted) }

      it { is_expected.to be_destroy }
    end
  end

  describe '#submit?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_submit }
    end

    context 'when user owns the request and it is in draft status' do
      let(:user) { request_owner }
      let(:reimbursement_request) { create(:reimbursement_request, user: request_owner, status: 'draft') }

      it { is_expected.to be_submit }
    end

    context 'when user owns the request but it is already submitted' do
      let(:user) { request_owner }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted, user: request_owner) }

      it { is_expected.not_to be_submit }
    end

    context 'when user does not own the request' do
      let(:user) { create(:user) }
      let(:reimbursement_request) { create(:reimbursement_request, status: 'draft') }

      it { is_expected.not_to be_submit }
    end
  end

  describe 'permitted_attributes' do
    let(:user) { create(:user, :submitter) }

    context 'for member users' do
      it 'returns allowed attributes for creation/update' do
        expected_attributes = [
          :title, :description, :amount_cents, :currency, :expense_date,
          :category, :priority, receipts: []
        ]
        expect(policy.permitted_attributes).to match_array(expected_attributes)
      end
    end
  end

  describe 'permitted_attributes_for_create' do
    let(:user) { create(:user, :submitter) }

    it 'returns attributes allowed for creation' do
      expected_attributes = [
        :title, :description, :amount_cents, :currency, :expense_date,
        :category, :priority, receipts: []
      ]
      expect(policy.permitted_attributes_for_create).to match_array(expected_attributes)
    end
  end

  describe 'permitted_attributes_for_update' do
    let(:user) { create(:user, :submitter) }

    context 'when request is in draft status' do
      let(:reimbursement_request) { create(:reimbursement_request, user: user, status: 'draft') }

      it 'returns all attributes allowed for update' do
        expected_attributes = [
          :title, :description, :amount_cents, :currency, :expense_date,
          :category, :priority, receipts: []
        ]
        expect(policy.permitted_attributes_for_update).to match_array(expected_attributes)
      end
    end

    context 'when request is submitted' do
      let(:reimbursement_request) { create(:reimbursement_request, :submitted, user: user) }

      it 'returns limited attributes' do
        expected_attributes = [ :receipts ]
        expect(policy.permitted_attributes_for_update).to match_array(expected_attributes)
      end
    end
  end
end

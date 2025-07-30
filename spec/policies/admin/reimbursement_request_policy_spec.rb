require 'rails_helper'

RSpec.describe Admin::ReimbursementRequestPolicy, type: :policy do
  subject(:policy) { described_class.new(user, reimbursement_request) }

  let(:reimbursement_request) { create(:reimbursement_request, :submitted) }

  describe 'Scope' do
    subject(:scope) { described_class::Scope.new(user, ReimbursementRequest.all).resolve }

    context 'when user is not present' do
      let(:user) { nil }
      let!(:any_request) { create(:reimbursement_request) }

      it 'returns empty scope' do
        expect(scope).to be_empty
      end
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }
      let!(:any_request) { create(:reimbursement_request) }

      it 'returns empty scope' do
        expect(scope).to be_empty
      end
    end

    context 'when user is treasury admin' do
      let(:user) { create(:user, :treasury_admin) }
      let!(:draft_request) { create(:reimbursement_request, status: 'draft') }
      let!(:submitted_request) { create(:reimbursement_request, :submitted) }
      let!(:approved_request) { create(:reimbursement_request, :approved) }

      it 'returns all requests' do
        expect(scope).to contain_exactly(draft_request, submitted_request, approved_request)
      end
    end

    context 'when user is system administrator' do
      let(:user) { create(:user, :system_administrator) }
      let!(:draft_request) { create(:reimbursement_request, status: 'draft') }
      let!(:submitted_request) { create(:reimbursement_request, :submitted) }
      let!(:approved_request) { create(:reimbursement_request, :approved) }

      it 'returns all requests' do
        expect(scope).to contain_exactly(draft_request, submitted_request, approved_request)
      end
    end

    context 'when user is chapter admin' do
      let(:user) { create(:user, :chapter_admin) }
      let!(:draft_request) { create(:reimbursement_request, status: 'draft') }
      let!(:submitted_request) { create(:reimbursement_request, :submitted) }
      let!(:approved_request) { create(:reimbursement_request, :approved) }

      it 'returns all requests' do
        expect(scope).to contain_exactly(draft_request, submitted_request, approved_request)
      end
    end
  end

  describe '#index?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_index }
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }

      it { is_expected.not_to be_index }
    end

    context 'when user is treasury admin' do
      let(:user) { create(:user, :treasury_admin) }

      it { is_expected.to be_index }
    end

    context 'when user is system administrator' do
      let(:user) { create(:user, :system_administrator) }

      it { is_expected.to be_index }
    end

    context 'when user is chapter admin' do
      let(:user) { create(:user, :chapter_admin) }

      it { is_expected.to be_index }
    end
  end

  describe '#show?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_show }
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }

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

  describe '#approve?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_approve }
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }

      it { is_expected.not_to be_approve }
    end

    context 'when user can approve and request is submitted' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted) }

      it { is_expected.to be_approve }
    end

    context 'when user can approve and request is under review' do
      let(:user) { create(:user, :chapter_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :under_review) }

      it { is_expected.to be_approve }
    end

    context 'when user can approve but request is draft' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, status: 'draft') }

      it { is_expected.not_to be_approve }
    end

    context 'when user can approve but request is already approved' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :approved) }

      it { is_expected.not_to be_approve }
    end

    context 'when user cannot approve' do
      let(:user) { create(:user, :viewer) }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted) }

      it { is_expected.not_to be_approve }
    end
  end

  describe '#reject?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_reject }
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }

      it { is_expected.not_to be_reject }
    end

    context 'when user can approve and request is submitted' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted) }

      it { is_expected.to be_reject }
    end

    context 'when user can approve and request is under review' do
      let(:user) { create(:user, :chapter_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :under_review) }

      it { is_expected.to be_reject }
    end

    context 'when user can approve but request is draft' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, status: 'draft') }

      it { is_expected.not_to be_reject }
    end

    context 'when user can approve but request is already approved' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :approved) }

      it { is_expected.not_to be_reject }
    end
  end

  describe '#request_info?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_request_info }
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }

      it { is_expected.not_to be_request_info }
    end

    context 'when user can approve and request is submitted' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted) }

      it { is_expected.to be_request_info }
    end

    context 'when user can approve but request is not submitted' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, status: 'draft') }

      it { is_expected.not_to be_request_info }
    end
  end

  describe '#mark_paid?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_mark_paid }
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }

      it { is_expected.not_to be_mark_paid }
    end

    context 'when user can process payments and request is approved' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :approved) }

      it { is_expected.to be_mark_paid }
    end

    context 'when user can process payments but request is not approved' do
      let(:user) { create(:user, :treasury_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :submitted) }

      it { is_expected.not_to be_mark_paid }
    end

    context 'when user cannot process payments' do
      let(:user) { create(:user, :chapter_admin) }
      let(:reimbursement_request) { create(:reimbursement_request, :approved) }

      it { is_expected.not_to be_mark_paid }
    end

    context 'when user is system administrator' do
      let(:user) { create(:user, :system_administrator) }
      let(:reimbursement_request) { create(:reimbursement_request, :approved) }

      it { is_expected.to be_mark_paid }
    end
  end

  describe '#update?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_update }
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }

      it { is_expected.not_to be_update }
    end

    context 'when user is treasury admin' do
      let(:user) { create(:user, :treasury_admin) }

      it { is_expected.to be_update }
    end

    context 'when user is system administrator' do
      let(:user) { create(:user, :system_administrator) }

      it { is_expected.to be_update }
    end
  end

  describe '#destroy?' do
    context 'when user is not present' do
      let(:user) { nil }

      it { is_expected.not_to be_destroy }
    end

    context 'when user is not an admin' do
      let(:user) { create(:user, :submitter) }

      it { is_expected.not_to be_destroy }
    end

    context 'when user is treasury admin' do
      let(:user) { create(:user, :treasury_admin) }

      it { is_expected.not_to be_destroy }
    end

    context 'when user is system administrator' do
      let(:user) { create(:user, :system_administrator) }

      it { is_expected.to be_destroy }
    end
  end

  describe 'permitted_attributes_for_approve' do
    let(:user) { create(:user, :treasury_admin) }

    it 'returns attributes allowed for approval' do
      expected_attributes = [ :approved_amount_cents, :approval_notes ]
      expect(policy.permitted_attributes_for_approve).to match_array(expected_attributes)
    end
  end

  describe 'permitted_attributes_for_reject' do
    let(:user) { create(:user, :treasury_admin) }

    it 'returns attributes allowed for rejection' do
      expected_attributes = [ :rejection_reason ]
      expect(policy.permitted_attributes_for_reject).to match_array(expected_attributes)
    end
  end

  describe 'permitted_attributes_for_request_info' do
    let(:user) { create(:user, :treasury_admin) }

    it 'returns attributes allowed for requesting info' do
      expected_attributes = [ :notes ]
      expect(policy.permitted_attributes_for_request_info).to match_array(expected_attributes)
    end
  end
end

require 'rails_helper'

RSpec.describe ReimbursementRequest, type: :model do
  describe 'validations' do
    subject { build(:reimbursement_request) }

    it 'validates presence of required fields' do
      request = described_class.new
      expect(request).not_to be_valid

      expect(request.errors[:title]).to include("can't be blank")
      expect(request.errors[:description]).to include("can't be blank")
      expect(request.errors[:amount_cents]).to include("can't be blank")
      expect(request.errors[:expense_date]).to include("can't be blank")
      expect(request.errors[:category]).to include("can't be blank")
      # Note: currency has a default value, so no validation error expected
      # Note: status has a default value, so no validation error expected
    end

    it 'validates amount_cents is greater than 0' do
      request = build(:reimbursement_request, amount_cents: 0)
      expect(request).not_to be_valid
      expect(request.errors[:amount_cents]).to include("must be greater than 0")

      request = build(:reimbursement_request, amount_cents: -100)
      expect(request).not_to be_valid
      expect(request.errors[:amount_cents]).to include("must be greater than 0")

      request = build(:reimbursement_request, amount_cents: 100)
      expect(request).to be_valid
    end

    it 'validates request_number uniqueness' do
      existing_request = create(:reimbursement_request, request_number: 'RB-2025-001')
      new_request = build(:reimbursement_request, request_number: 'RB-2025-001')

      expect(new_request).not_to be_valid
      expect(new_request.errors[:request_number]).to include("has already been taken")
    end

    it 'validates currency format' do
      valid_currencies = %w[USD EUR GBP]
      valid_currencies.each do |currency|
        request = build(:reimbursement_request, currency: currency)
        expect(request).to be_valid
      end

      invalid_currencies = %w[usd US USDT invalid]
      invalid_currencies.each do |currency|
        request = build(:reimbursement_request, currency: currency)
        expect(request).not_to be_valid
        expect(request.errors[:currency]).to include("must be a valid 3-letter ISO currency code")
      end
    end

    it 'validates category inclusion' do
      valid_categories = %w[travel accommodation meals supplies communications events other]
      valid_categories.each do |category|
        request = build(:reimbursement_request, category: category)
        expect(request).to be_valid
      end

      # Test invalid category raises ArgumentError due to enum
      request = build(:reimbursement_request)
      expect {
        request.category = 'invalid_category'
      }.to raise_error(ArgumentError, "'invalid_category' is not a valid category")
    end

    it 'validates priority inclusion' do
      valid_priorities = %w[low normal high urgent]
      valid_priorities.each do |priority|
        request = build(:reimbursement_request, priority: priority)
        expect(request).to be_valid
      end

      # Test invalid priority raises ArgumentError due to enum
      request = build(:reimbursement_request)
      expect {
        request.priority = 'invalid_priority'
      }.to raise_error(ArgumentError, "'invalid_priority' is not a valid priority")
    end

    it 'validates expense_date is not in the future' do
      request = build(:reimbursement_request, expense_date: Date.current)
      expect(request).to be_valid

      request = build(:reimbursement_request, expense_date: 1.day.ago)
      expect(request).to be_valid

      request = build(:reimbursement_request, expense_date: 1.day.from_now)
      expect(request).not_to be_valid
      expect(request.errors[:expense_date]).to include("cannot be in the future")
    end

    context 'when status is submitted' do
      it 'validates submitted_at is present' do
        request = build(:reimbursement_request, status: 'submitted', submitted_at: nil)
        expect(request).not_to be_valid
        expect(request.errors[:submitted_at]).to include("must be present")
      end
    end

    context 'when status is approved' do
      it 'validates required approval fields' do
        request = build(:reimbursement_request,
          status: 'approved',
          submitted_at: nil,
          approved_at: nil,
          approved_by_id: nil,
          approved_amount_cents: nil
        )
        expect(request).not_to be_valid
        expect(request.errors[:submitted_at]).to include("must be present")
        expect(request.errors[:approved_at]).to include("must be present")
        expect(request.errors[:approved_by_id]).to include("must be present")
        expect(request.errors[:approved_amount_cents]).to include("must be present when approved")
      end
    end

    context 'when status is rejected' do
      it 'validates required rejection fields' do
        request = build(:reimbursement_request,
          status: 'rejected',
          submitted_at: nil,
          rejected_at: nil,
          rejection_reason: nil
        )
        expect(request).not_to be_valid
        expect(request.errors[:submitted_at]).to include("must be present")
        expect(request.errors[:rejected_at]).to include("must be present")
        expect(request.errors[:rejection_reason]).to include("must be present when rejected")
      end
    end

    context 'when status is paid' do
      it 'validates required payment fields' do
        request = build(:reimbursement_request,
          status: 'paid',
          submitted_at: nil,
          approved_at: nil,
          approved_by_id: nil,
          paid_at: nil
        )
        expect(request).not_to be_valid
        expect(request.errors[:submitted_at]).to include("must be present")
        expect(request.errors[:approved_at]).to include("must be present")
        expect(request.errors[:approved_by_id]).to include("must be present")
        expect(request.errors[:paid_at]).to include("must be present")
      end
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      association = described_class.reflect_on_association(:user)
      expect(association.macro).to eq(:belongs_to)
    end

    it 'belongs to approved_by user (optional)' do
      association = described_class.reflect_on_association(:approved_by)
      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq('User')
      expect(association.options[:optional]).to be true
    end

    it 'has many events' do
      association = described_class.reflect_on_association(:events)
      expect(association.macro).to eq(:has_many)
      expect(association.class_name).to eq('ReimbursementRequestEvent')
    end

    it 'has many attached receipts' do
      request = create(:reimbursement_request)
      expect(request.receipts).to be_an_instance_of(ActiveStorage::Attached::Many)
    end
  end

  describe 'enums' do
    it 'defines status enum' do
      expect(described_class.statuses).to eq({
        'draft' => 'draft',
        'submitted' => 'submitted',
        'under_review' => 'under_review',
        'approved' => 'approved',
        'rejected' => 'rejected',
        'paid' => 'paid'
      })
    end

    it 'defines category enum' do
      expect(described_class.categories).to eq({
        'travel' => 'travel',
        'accommodation' => 'accommodation',
        'meals' => 'meals',
        'supplies' => 'supplies',
        'communications' => 'communications',
        'events' => 'events',
        'other' => 'other'
      })
    end

    it 'defines priority enum' do
      expect(described_class.priorities).to eq({
        'low' => 'low',
        'normal' => 'normal',
        'high' => 'high',
        'urgent' => 'urgent'
      })
    end
  end

  describe 'scopes' do
    let!(:draft_request) { create(:reimbursement_request, status: 'draft') }
    let!(:submitted_request) { create(:reimbursement_request, :submitted) }
    let!(:approved_request) { create(:reimbursement_request, :approved) }

    describe '.by_status' do
      it 'filters by status' do
        expect(described_class.by_status('draft')).to contain_exactly(draft_request)
        expect(described_class.by_status('submitted')).to contain_exactly(submitted_request)
        expect(described_class.by_status('approved')).to contain_exactly(approved_request)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        expect(described_class.recent).to eq([ approved_request, submitted_request, draft_request ])
      end
    end

    describe '.pending_approval' do
      it 'includes submitted and under_review requests' do
        under_review_request = create(:reimbursement_request, :under_review)
        expect(described_class.pending_approval).to contain_exactly(submitted_request, under_review_request)
      end
    end

    describe '.for_user' do
      let(:user1) { create(:user) }
      let(:user2) { create(:user) }
      let!(:user1_request) { create(:reimbursement_request, user: user1) }
      let!(:user2_request) { create(:reimbursement_request, user: user2) }

      it 'filters by user' do
        expect(described_class.for_user(user1)).to contain_exactly(user1_request)
        expect(described_class.for_user(user2)).to contain_exactly(user2_request)
      end
    end
  end

  describe 'callbacks' do
    describe 'before_validation' do
      context 'on create' do
        it 'generates request_number' do
          request = build(:reimbursement_request, request_number: nil)
          request.valid?
          expect(request.request_number).to match(/^RB-\d{4}-\d{3}$/)
        end

        it 'sets default priority' do
          request = build(:reimbursement_request, priority: nil)
          request.valid?
          expect(request.priority).to eq('normal')
        end

        it 'sets default currency' do
          request = build(:reimbursement_request, currency: nil)
          request.valid?
          expect(request.currency).to eq('USD')
        end
      end
    end
  end

  describe 'state transition methods' do
    let(:user) { create(:user) }
    let(:approver) { create(:user) }
    let(:request) { create(:reimbursement_request, status: 'draft', user: user) }

    describe '#submit!' do
      it 'transitions from draft to submitted' do
        expect { request.submit!(user) }.to change(request, :status).from('draft').to('submitted')
        expect(request.submitted_at).to be_present
        expect(request.events.last.event_type).to eq('submitted')
      end

      it 'raises error if not in draft status' do
        request.submit!(user) # First submit to change status
        expect { request.submit!(user) }.to raise_error(ReimbursementRequest::InvalidTransition)
      end
    end

    describe '#approve!' do
      before { request.update!(status: 'submitted', submitted_at: 1.day.ago) }

      it 'transitions from submitted to approved' do
        expect { request.approve!(approver, amount: 10000, notes: 'Approved') }
          .to change(request, :status).from('submitted').to('approved')

        expect(request.approved_at).to be_present
        expect(request.approved_by).to eq(approver)
        expect(request.approved_amount_cents).to eq(10000)
        expect(request.approval_notes).to eq('Approved')
        expect(request.events.last.event_type).to eq('approved')
      end

      it 'uses original amount if no amount specified' do
        original_amount = request.amount_cents
        request.approve!(approver)
        expect(request.approved_amount_cents).to eq(original_amount)
      end

      it 'raises error if not in submitted or under_review status' do
        request.update!(status: 'draft')
        expect { request.approve!(approver) }.to raise_error(ReimbursementRequest::InvalidTransition)
      end
    end

    describe '#reject!' do
      before { request.update!(status: 'submitted', submitted_at: 1.day.ago) }

      it 'transitions from submitted to rejected' do
        expect { request.reject!(approver, reason: 'Insufficient documentation') }
          .to change(request, :status).from('submitted').to('rejected')

        expect(request.rejected_at).to be_present
        expect(request.rejection_reason).to eq('Insufficient documentation')
        expect(request.events.last.event_type).to eq('rejected')
      end

      it 'raises error if not in submitted or under_review status' do
        request.update!(status: 'draft')
        expect { request.reject!(approver, reason: 'Test') }.to raise_error(ReimbursementRequest::InvalidTransition)
      end
    end

    describe '#mark_paid!' do
      before do
        request.update!(
          status: 'approved',
          submitted_at: 2.days.ago,
          approved_at: 1.day.ago,
          approved_by: approver,
          approved_amount_cents: 10000
        )
      end

      it 'transitions from approved to paid' do
        expect { request.mark_paid!(user) }.to change(request, :status).from('approved').to('paid')
        expect(request.paid_at).to be_present
        expect(request.events.last.event_type).to eq('paid')
      end

      it 'raises error if not in approved status' do
        request.update!(status: 'submitted')
        expect { request.mark_paid!(user) }.to raise_error(ReimbursementRequest::InvalidTransition)
      end
    end

    describe '#request_more_info!' do
      before { request.update!(status: 'submitted', submitted_at: 1.day.ago) }

      it 'transitions from submitted to under_review' do
        expect { request.request_more_info!(approver, notes: 'Need receipt') }
          .to change(request, :status).from('submitted').to('under_review')

        expect(request.reviewed_at).to be_present
        expect(request.events.last.event_type).to eq('info_requested')
      end
    end
  end

  describe 'query methods' do
    let(:request) { create(:reimbursement_request) }

    describe 'status predicates' do
      it 'provides status predicate methods' do
        expect(request).to respond_to(:draft?)
        expect(request).to respond_to(:submitted?)
        expect(request).to respond_to(:under_review?)
        expect(request).to respond_to(:approved?)
        expect(request).to respond_to(:rejected?)
        expect(request).to respond_to(:paid?)
      end
    end

    describe '#can_submit?' do
      it 'returns true for draft status' do
        request.status = 'draft'
        expect(request.can_submit?).to be true
      end

      it 'returns false for non-draft status' do
        request.status = 'submitted'
        expect(request.can_submit?).to be false
      end
    end

    describe '#can_approve?' do
      it 'returns true for submitted and under_review status' do
        request.status = 'submitted'
        expect(request.can_approve?).to be true

        request.status = 'under_review'
        expect(request.can_approve?).to be true
      end

      it 'returns false for other statuses' do
        request.status = 'draft'
        expect(request.can_approve?).to be false

        request.status = 'approved'
        expect(request.can_approve?).to be false
      end
    end

    describe '#can_reject?' do
      it 'returns true for submitted and under_review status' do
        request.status = 'submitted'
        expect(request.can_reject?).to be true

        request.status = 'under_review'
        expect(request.can_reject?).to be true
      end

      it 'returns false for other statuses' do
        request.status = 'draft'
        expect(request.can_reject?).to be false

        request.status = 'approved'
        expect(request.can_reject?).to be false
      end
    end

    describe '#can_mark_paid?' do
      it 'returns true for approved status' do
        request.status = 'approved'
        expect(request.can_mark_paid?).to be true
      end

      it 'returns false for other statuses' do
        request.status = 'submitted'
        expect(request.can_mark_paid?).to be false
      end
    end
  end

  describe 'amount formatting' do
    let(:request) { build(:reimbursement_request, amount_cents: 12345, currency: 'USD') }

    describe '#amount' do
      it 'returns amount in dollars' do
        expect(request.amount).to eq(123.45)
      end
    end

    describe '#formatted_amount' do
      it 'returns formatted currency string' do
        expect(request.formatted_amount).to eq('$123.45')
      end
    end

    describe '#approved_amount' do
      it 'returns approved amount in dollars when present' do
        request.approved_amount_cents = 10000
        expect(request.approved_amount).to eq(100.00)
      end

      it 'returns nil when approved_amount_cents is nil' do
        request.approved_amount_cents = nil
        expect(request.approved_amount).to be_nil
      end
    end
  end

  describe 'audit trail' do
    let(:user) { create(:user) }
    let(:request) { create(:reimbursement_request, user: user) }

    it 'creates events for state transitions' do
      expect { request.submit!(user) }.to change { request.events.count }.by(1)

      event = request.events.last
      expect(event.event_type).to eq('submitted')
      expect(event.user).to eq(user)
      expect(event.from_status).to eq('draft')
      expect(event.to_status).to eq('submitted')
    end
  end
end

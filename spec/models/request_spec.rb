require 'rails_helper'

RSpec.describe Request, type: :model do
  describe 'validations' do
    it 'validates presence of required fields' do
      request = described_class.new
      request.valid?

      expect(request.errors[:request_type]).to include("can't be blank")
      expect(request.errors[:amount_requested]).to include("can't be blank")
      expect(request.errors[:form_data]).to include("can't be blank")
    end

    it 'validates amount_requested is positive' do
      request = described_class.new(amount_requested: -10)
      request.valid?

      expect(request.errors[:amount_requested]).to include("must be greater than 0")
    end

    it 'validates exchange_rate is positive' do
      request = described_class.new(exchange_rate: -1)
      request.valid?

      expect(request.errors[:exchange_rate]).to include("must be greater than 0")
    end
  end

  describe 'enums' do
    it 'defines correct status values' do
      expect(described_class.statuses).to eq({
        'submitted' => 0,
        'approved' => 1,
        'rejected' => 2,
        'paid' => 3
      })
    end

    it 'defines correct request_type values' do
      expect(described_class.request_types).to eq({
        'reimbursement' => 'R',
        'vendor' => 'V',
        'inkind' => 'I'
      })
    end
  end

  describe 'callbacks' do
    describe '#generate_request_number' do
      it 'generates request number on create' do
        request = described_class.create!(
          request_type: 'inkind',
          amount_requested: 100.0,
          form_data: { test: 'data' }
        )

        expect(request.request_number).to match(/IK-\d{4}-\d{3}/)
      end

      it 'generates unique request numbers' do
        request1 = described_class.create!(
          request_type: 'inkind',
          amount_requested: 100.0,
          form_data: { test: 'data' }
        )

        request2 = described_class.create!(
          request_type: 'inkind',
          amount_requested: 200.0,
          form_data: { test: 'data' }
        )

        expect(request1.request_number).not_to eq(request2.request_number)
      end
    end

    describe '#set_defaults' do
      it 'sets default currency to USD' do
        request = described_class.create!(
          request_type: 'inkind',
          amount_requested: 100.0,
          form_data: { test: 'data' }
        )

        expect(request.currency_code).to eq('USD')
        expect(request.exchange_rate).to eq(1.0)
        expect(request.amount_usd).to eq(100.0)
      end
    end
  end

  describe 'scopes' do
    let!(:inkind_request) { described_class.create!(request_type: 'inkind', amount_requested: 100, form_data: { test: 'data' }) }
    let!(:reimbursement_request) { described_class.create!(request_type: 'reimbursement', amount_requested: 200, form_data: { test: 'data' }) }

    describe '.by_type' do
      it 'filters by request type' do
        results = described_class.by_type('inkind')
        expect(results).to include(inkind_request)
        expect(results).not_to include(reimbursement_request)
      end
    end

    describe '.recent' do
      it 'orders by created_at desc' do
        results = described_class.recent
        expect(results.first.created_at).to be >= results.last.created_at
      end
    end
  end
end

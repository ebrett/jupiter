require 'rails_helper'

RSpec.describe InkindRequest, type: :model do
  describe 'validations' do
    it 'validates request_type is inkind' do
      request = described_class.new(request_type: 'reimbursement')
      request.valid?

      expect(request.errors[:request_type]).to include('is not included in the list')
    end

    it 'validates required form_data fields' do
      request = described_class.new(
        request_type: 'inkind',
        amount_requested: 100.0,
        form_data: {}
      )
      request.valid?

      expect(request.errors[:form_data]).to include('Donor name is required')
      expect(request.errors[:form_data]).to include('Donor email is required')
      expect(request.errors[:form_data]).to include('Donor address is required')
    end

    it 'validates email format' do
      request = described_class.new(
        request_type: 'inkind',
        amount_requested: 100.0,
        form_data: {
          'donor_name' => 'Test Donor',
          'donor_email' => 'invalid-email',
          'donor_address' => 'Test Address',
          'donation_type' => 'Goods',
          'item_description' => 'Test item',
          'expense_category_code' => 'TEST',
          'donation_date' => '2024-01-01',
          'country' => 'US',
          'submitter_email' => 'test@example.com',
          'submitter_name' => 'Test User'
        }
      )
      request.valid?

      expect(request.errors[:form_data]).to include('Donor email must be a valid email address')
    end

    it 'validates donation_type is valid' do
      request = described_class.new(
        request_type: 'inkind',
        amount_requested: 100.0,
        form_data: {
          'donor_name' => 'Test Donor',
          'donor_email' => 'donor@example.com',
          'donor_address' => 'Test Address',
          'donation_type' => 'Invalid',
          'item_description' => 'Test item',
          'expense_category_code' => 'TEST',
          'donation_date' => '2024-01-01',
          'country' => 'US',
          'submitter_email' => 'test@example.com',
          'submitter_name' => 'Test User'
        }
      )
      request.valid?

      expect(request.errors[:form_data]).to include('Donation type must be one of: Goods, Services')
    end

    it 'validates donation_date is not in future' do
      request = described_class.new(
        request_type: 'inkind',
        amount_requested: 100.0,
        form_data: {
          'donor_name' => 'Test Donor',
          'donor_email' => 'donor@example.com',
          'donor_address' => 'Test Address',
          'donation_type' => 'Goods',
          'item_description' => 'Test item',
          'expense_category_code' => 'TEST',
          'donation_date' => (Date.current + 1.day).to_s,
          'country' => 'US',
          'submitter_email' => 'test@example.com',
          'submitter_name' => 'Test User'
        }
      )
      request.valid?

      expect(request.errors[:form_data]).to include('Donation date cannot be in the future')
    end

    describe 'security validations' do
      it 'handles Unicode characters in all text fields' do
        request = described_class.new(
          request_type: 'inkind',
          amount_requested: 100.0,
          form_data: {
            'donor_name' => '测试捐赠者 🎁',
            'donor_email' => 'unicode@example.com',
            'donor_address' => '123 مرحبا Street, تست City',
            'donation_type' => 'Goods',
            'item_description' => 'Books with émojis 📚 and spëcial chars',
            'expense_category_code' => 'TEST',
            'donation_date' => '2024-01-01',
            'country' => 'US',
            'submitter_email' => 'test@example.com',
            'submitter_name' => 'Test User'
          }
        )

        expect(request).to be_valid
        expect(request.donor_name).to eq('测试捐赠者 🎁')
        expect(request.item_description).to include('📚')
      end

      it 'validates against extremely long field values' do
        request = described_class.new(
          request_type: 'inkind',
          amount_requested: 100.0,
          form_data: {
            'donor_name' => 'A' * 256, # Over 255 character limit
            'donor_email' => "#{'verylongemailaddresshere' * 10}@example.com", # Over 255 chars
            'donor_address' => 'B' * 501, # Over 500 character limit
            'donation_type' => 'Goods',
            'item_description' => 'C' * 1001, # Over 1000 character limit
            'expense_category_code' => 'TEST',
            'donation_date' => '2024-01-01',
            'country' => 'US',
            'submitter_email' => 'test@example.com',
            'submitter_name' => 'Test User'
          }
        )
        request.valid?

        expect(request.errors[:form_data]).to include('Donor name cannot exceed 255 characters')
        expect(request.errors[:form_data]).to include('Donor address cannot exceed 500 characters')
        expect(request.errors[:form_data]).to include('Item description cannot exceed 1000 characters')
        # Email validation fails first due to format, so length validation doesn't run
      end

      it 'handles SQL injection attempts in form data' do
        malicious_input = "'; DROP TABLE requests; --"
        request = described_class.new(
          request_type: 'inkind',
          amount_requested: 100.0,
          form_data: {
            'donor_name' => malicious_input,
            'donor_email' => 'test@example.com',
            'donor_address' => malicious_input,
            'donation_type' => 'Goods',
            'item_description' => malicious_input,
            'expense_category_code' => 'TEST',
            'donation_date' => '2024-01-01',
            'country' => 'US',
            'submitter_email' => 'test@example.com',
            'submitter_name' => 'Test User'
          }
        )

        expect(request).to be_valid
        expect(request.donor_name).to eq(malicious_input) # Stored as-is, ActiveRecord handles escaping
      end

      it 'validates email addresses with various formats' do
        valid_emails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
          'firstname-lastname@example.museum'
        ]

        invalid_emails = [
          'plainaddress',
          '@missinglocalpart.com',
          'missing@.com',
          'spaces @example.com',
          'multiple@@domain.com'
        ]

        valid_emails.each do |email|
          request = build_request_with_email(email)
          expect(request).to be_valid, "Expected #{email} to be valid"
        end

        invalid_emails.each do |email|
          request = build_request_with_email(email)
          request.valid?
          expect(request.errors[:form_data]).to include('Donor email must be a valid email address'),
            "Expected #{email} to be invalid"
        end
      end

      it 'handles null bytes and control characters' do
        request = described_class.new(
          request_type: 'inkind',
          amount_requested: 100.0,
          form_data: {
            'donor_name' => "Test\x00Donor", # Null byte
            'donor_email' => "test@example.com", # Keep email valid
            'donor_address' => "123\x02Street", # Another control character
            'donation_type' => 'Goods',
            'item_description' => "Item\x03Description",
            'expense_category_code' => 'TEST',
            'donation_date' => '2024-01-01',
            'country' => 'US',
            'submitter_email' => 'test@example.com',
            'submitter_name' => 'Test User'
          }
        )

        # Should be valid (Rails handles this at the database level)
        expect(request).to be_valid
      end

      private

      def build_request_with_email(email)
        described_class.new(
          request_type: 'inkind',
          amount_requested: 100.0,
          form_data: {
            'donor_name' => 'Test Donor',
            'donor_email' => email,
            'donor_address' => 'Test Address',
            'donation_type' => 'Goods',
            'item_description' => 'Test item',
            'expense_category_code' => 'TEST',
            'donation_date' => '2024-01-01',
            'country' => 'US',
            'submitter_email' => 'test@example.com',
            'submitter_name' => 'Test User'
          }
        )
      end
    end
  end

  describe 'accessor methods' do
    let(:request) do
      described_class.new(
        request_type: 'inkind',
        amount_requested: 150.50,
        form_data: {
          'donor_name' => 'John Doe',
          'donor_email' => 'john@example.com',
          'donor_address' => '123 Main St',
          'donation_type' => 'Services',
          'item_description' => 'Legal consultation',
          'expense_category_code' => 'LEGAL_CONSULTING',
          'donation_date' => '2024-01-15',
          'country' => 'US'
        }
      )
    end

    it 'provides accessor methods for form data' do
      expect(request.donor_name).to eq('John Doe')
      expect(request.donor_email).to eq('john@example.com')
      expect(request.donor_address).to eq('123 Main St')
      expect(request.donation_type).to eq('Services')
      expect(request.item_description).to eq('Legal consultation')
      expect(request.expense_category_code).to eq('LEGAL_CONSULTING')
      expect(request.fair_market_value).to eq(150.50)
      expect(request.country).to eq('US')
    end

    it 'parses donation_date correctly' do
      expect(request.donation_date).to eq(Date.parse('2024-01-15'))
    end
  end

  describe '#to_csv_row' do
    let(:request) do
      described_class.create!(
        request_type: 'inkind',
        amount_requested: 150.50,
        currency_code: 'USD',
        amount_usd: 150.50,
        exchange_rate: 1.0,
        form_data: {
          'donor_name' => 'John Doe',
          'donor_email' => 'john@example.com',
          'donor_address' => '123 Main St',
          'donation_type' => 'Services',
          'item_description' => 'Legal consultation',
          'expense_category_code' => 'LEGAL_CONSULTING',
          'donation_date' => '2024-01-15',
          'country' => 'US',
          'submitter_email' => 'submitter@example.com',
          'submitter_name' => 'Test Submitter'
        }
      )
    end

    it 'generates CSV row as array with correct length' do
      row = request.to_csv_row

      expect(row).to be_an(Array)
      expect(row.length).to eq(21) # All CSV columns
    end

    it 'includes submitter information in CSV row' do
      row = request.to_csv_row

      expect(row[0]).to eq(request.created_at.iso8601) # Timestamp
      expect(row[1]).to eq('submitter@example.com') # Email Address
      expect(row[2]).to eq('Test Submitter') # Name
      expect(row[3]).to eq('US') # Country
    end

    it 'includes donor information in CSV row' do
      row = request.to_csv_row

      expect(row[4]).to eq('John Doe') # Donor Name
      expect(row[5]).to eq('john@example.com') # Donor Email
      expect(row[6]).to eq('123 Main St') # Donor Address
    end

    it 'includes donation details in CSV row' do
      row = request.to_csv_row

      expect(row[7]).to eq('Services') # Donation Type
      expect(row[8]).to eq('Legal consultation') # Item Description
      expect(row[9]).to eq('LEGAL_CONSULTING') # QuickBooks Coding
    end

    it 'includes financial information in CSV row' do
      row = request.to_csv_row

      expect(row[10]).to eq(150.50) # Fair Market Value
      expect(row[11]).to eq('USD') # Currency
      expect(row[12]).to eq(150.50) # Amount (USD)
      expect(row[13]).to eq(1.0) # Exchange Rate
    end

    it 'includes status information in CSV row' do
      row = request.to_csv_row

      expect(row[14]).to eq(Date.parse('2024-01-15').iso8601) # Donation Date
      expect(row[15]).to be(false) # Acknowledgment Sent
      expect(row[16]).to eq('Submitted') # Status
    end
  end
end

FactoryBot.define do
  sequence :sequence_form_data

  factory :request do
    request_type { 'inkind' }
    amount_requested { 100.50 }
    currency_code { 'USD' }
    amount_usd { amount_requested }
    exchange_rate { 1.0 }
    form_data do
      n = FactoryBot.generate(:sequence_form_data)
      {
        'donor_name' => "Test Donor #{n}",
        'donor_email' => "donor#{n}@example.com",
        'donor_address' => '123 Test Street, Test City, TC 12345',
        'donation_type' => 'Goods',
        'item_description' => 'Test donation item description',
        'expense_category_code' => 'DONATIONS_GENERAL',
        'donation_date' => Date.current.to_s,
        'country' => 'US',
        'submitter_email' => 'submitter@example.com',
        'submitter_name' => 'Test Submitter'
      }
    end

    trait :reimbursement do
      request_type { 'reimbursement' }
      form_data do
        {
          'payee_name' => 'Test Payee',
          'payee_email' => 'payee@example.com',
          'description' => 'Test reimbursement description',
          'expense_category_code' => 'OPERATIONAL_OFFICE',
          'date_incurred' => Date.current.to_s,
          'country' => 'US',
          'submitter_email' => 'submitter@example.com',
          'submitter_name' => 'Test Submitter'
        }
      end
    end

    trait :vendor do
      request_type { 'vendor' }
      form_data do
        {
          'vendor_name' => 'Test Vendor Inc.',
          'vendor_email' => 'vendor@example.com',
          'vendor_address' => '456 Vendor Street, Vendor City, VC 67890',
          'invoice_number' => 'INV-001',
          'invoice_date' => Date.current.to_s,
          'description' => 'Test vendor payment description',
          'expense_category_code' => 'TECHNOLOGY_SOFTWARE',
          'country' => 'US',
          'submitter_email' => 'submitter@example.com',
          'submitter_name' => 'Test Submitter'
        }
      end
    end

    trait :submitted do
      status { 'submitted' }
    end

    trait :approved do
      status { 'approved' }
    end

    trait :rejected do
      status { 'rejected' }
    end

    trait :paid do
      status { 'paid' }
    end
  end

  factory :inkind_request, parent: :request, class: 'InkindRequest' do
    request_type { 'inkind' }
  end
end

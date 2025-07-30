FactoryBot.define do
  factory :reimbursement_request do
    association :user

    title { "Conference travel expenses" }
    description { "Travel expenses for attending Democrats Abroad conference in Berlin" }
    amount_cents { 25000 } # $250.00
    currency { "USD" }
    expense_date { 1.week.ago.to_date }
    category { "travel" }
    priority { "normal" }
    status { "draft" }

    # Generate unique request number
    sequence(:request_number) { |n| "RB-#{Date.current.year}-#{n.to_s.rjust(3, '0')}" }

    trait :submitted do
      status { "submitted" }
      submitted_at { 1.day.ago }
    end

    trait :under_review do
      status { "under_review" }
      submitted_at { 2.days.ago }
      reviewed_at { 1.day.ago }
    end

    trait :approved do
      status { "approved" }
      submitted_at { 3.days.ago }
      approved_at { 1.day.ago }
      association :approved_by, factory: :user
      approved_amount_cents { amount_cents }
      approval_notes { "Approved as requested" }
    end

    trait :rejected do
      status { "rejected" }
      submitted_at { 3.days.ago }
      rejected_at { 1.day.ago }
      rejection_reason { "Insufficient documentation provided" }
    end

    trait :paid do
      status { "paid" }
      submitted_at { 5.days.ago }
      approved_at { 3.days.ago }
      paid_at { 1.day.ago }
      association :approved_by, factory: :user
      approved_amount_cents { amount_cents }
      approval_notes { "Approved and processed" }
    end

    trait :high_priority do
      priority { "high" }
      title { "Urgent: Emergency travel expenses" }
    end

    trait :urgent_priority do
      priority { "urgent" }
      title { "URGENT: Critical event expenses" }
    end

    trait :with_receipts do
      after(:create) do |request|
        # Simulate attached receipt files
        request.receipts.attach(
          io: StringIO.new("fake receipt content"),
          filename: "receipt.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :large_amount do
      amount_cents { 500000 } # $5,000.00
      title { "Large conference and accommodation expenses" }
      description { "Major expenses requiring special approval" }
      priority { "high" }
    end

    trait :accommodation do
      category { "accommodation" }
      title { "Hotel accommodation" }
      description { "Hotel stay for Democrats Abroad regional meeting" }
      amount_cents { 35000 } # $350.00
    end

    trait :meals do
      category { "meals" }
      title { "Conference meals" }
      description { "Meal expenses during three-day conference" }
      amount_cents { 15000 } # $150.00
    end

    trait :supplies do
      category { "supplies" }
      title { "Office supplies for event" }
      description { "Promotional materials and office supplies for voter registration drive" }
      amount_cents { 8000 } # $80.00
    end

    trait :communications do
      category { "communications" }
      title { "Website and communications costs" }
      description { "Monthly website hosting and communication platform fees" }
      amount_cents { 12000 } # $120.00
    end

    trait :events do
      category { "events" }
      title { "Community event expenses" }
      description { "Venue rental and refreshments for town hall meeting" }
      amount_cents { 45000 } # $450.00
    end

    trait :other do
      category { "other" }
      title { "Miscellaneous expenses" }
      description { "Various small expenses not fitting other categories" }
      amount_cents { 7500 } # $75.00
    end

    # Different currency examples
    trait :eur_currency do
      currency { "EUR" }
      amount_cents { 20000 } # €200.00
      title { "European chapter expenses" }
      description { "Local expenses for Berlin chapter activities" }
    end

    trait :gbp_currency do
      currency { "GBP" }
      amount_cents { 18000 } # £180.00
      title { "UK chapter expenses" }
      description { "Expenses for London chapter meeting" }
    end
  end
end

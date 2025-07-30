FactoryBot.define do
  factory :reimbursement_request_event do
    association :reimbursement_request
    association :user

    event_type { "submitted" }
    from_status { "draft" }
    to_status { "submitted" }
    event_data { {} }

    trait :submitted do
      event_type { "submitted" }
      from_status { "draft" }
      to_status { "submitted" }
    end

    trait :approved do
      event_type { "approved" }
      from_status { "submitted" }
      to_status { "approved" }
      event_data { { notes: "Approved as requested", amount: 25000 } }
    end

    trait :rejected do
      event_type { "rejected" }
      from_status { "submitted" }
      to_status { "rejected" }
      event_data { { reason: "Insufficient documentation" } }
    end

    trait :paid do
      event_type { "paid" }
      from_status { "approved" }
      to_status { "paid" }
    end

    trait :info_requested do
      event_type { "info_requested" }
      from_status { "submitted" }
      to_status { "under_review" }
      event_data { { notes: "Please provide additional receipts" } }
    end

    trait :with_notes do
      notes { "Additional context for this event" }
    end
  end
end

FactoryBot.define do
  factory :role do
    # Use find_or_initialize_by to avoid duplicates
    initialize_with { Role.find_or_initialize_by(name: name) }

    name { "submitter" }
    description { "Can create and submit reimbursement requests" }

    trait :submitter do
      name { "submitter" }
      description { "Can create and submit reimbursement requests" }
    end

    trait :country_chapter_admin do
      name { "country_chapter_admin" }
      description { "Can approve/deny requests for their region" }
    end

    trait :treasury_team_admin do
      name { "treasury_team_admin" }
      description { "Can process payments and manage financial operations" }
    end

    trait :super_admin do
      name { "super_admin" }
      description { "Full system access and user management" }
    end

    trait :viewer do
      name { "viewer" }
      description { "Read-only access to view requests and reports" }
    end
  end
end

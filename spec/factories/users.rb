FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_system_administrator_role do
      after(:create) do |user|
        role = Role.find_or_create_by(name: "system_administrator") do |r|
          r.description = "Full system access and user management"
        end
        user.roles << role unless user.roles.include?(role)
      end
    end

    trait :with_submitter_role do
      after(:create) do |user|
        role = Role.find_or_create_by(name: "submitter") do |r|
          r.description = "Can create and submit reimbursement requests"
        end
        user.roles << role unless user.roles.include?(role)
      end
    end

    trait :with_treasury_team_admin_role do
      after(:create) do |user|
        role = Role.find_or_create_by(name: "treasury_team_admin") do |r|
          r.description = "Can process payments and manage financial operations"
        end
        user.roles << role unless user.roles.include?(role)
      end
    end

    trait :with_country_chapter_admin_role do
      after(:create) do |user|
        role = Role.find_or_create_by(name: "country_chapter_admin") do |r|
          r.description = "Can approve/deny requests for their region"
        end
        user.roles << role unless user.roles.include?(role)
      end
    end
  end
end 
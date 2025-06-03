FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :with_super_admin_role do
      after(:create) do |user|
        role = Role.find_or_create_by(name: "super_admin") do |r|
          r.description = "Full system access and user management"
        end
        user.user_roles.create!(role: role)
      end
    end

    trait :with_submitter_role do
      after(:create) do |user|
        role = Role.find_or_create_by(name: "submitter") do |r|
          r.description = "Can create and submit reimbursement requests"
        end
        user.user_roles.create!(role: role)
      end
    end

    trait :with_treasury_admin_role do
      after(:create) do |user|
        role = Role.find_or_create_by(name: "treasury_team_admin") do |r|
          r.description = "Can process payments and manage financial operations"
        end
        user.user_roles.create!(role: role)
      end
    end
  end
end

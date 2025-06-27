FactoryBot.define do
  factory :expense_category do
    sequence(:code) { |n| "CATEGORY_#{n}" }
    sequence(:name) { |n| "Category #{n}" }
    active { true }
    parent { nil }

    trait :inactive do
      active { false }
    end

    trait :with_parent do
      association :parent, factory: :expense_category
    end

    trait :with_children do
      after(:create) do |category|
        create_list(:expense_category, 2, parent: category)
      end
    end

    # Common expense categories used in tests
    trait :office_supplies do
      code { "OFFICE_SUPPLIES" }
      name { "Office Supplies" }
    end

    trait :travel do
      code { "TRAVEL" }
      name { "Travel" }
    end

    trait :donations_general do
      code { "DONATIONS_GENERAL" }
      name { "Donations - General" }
    end
  end
end

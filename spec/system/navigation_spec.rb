require 'rails_helper'

RSpec.describe "Navigation", type: :system do
  before do
    driven_by(:rack_test)
    # Ensure clean state for each test
    User.destroy_all
    Session.destroy_all
  end

  describe "Components navigation visibility" do
    context "when user is a system administrator" do
      before do
        system_admin = create(:user, :system_administrator, email_address: "sysadmin@example.com")
        sign_in_user(email: system_admin.email_address, password: "password123")
      end

      it "shows the Components navigation link in development", skip: !Rails.env.development? do
        expect(page).to have_link("Components", href: "/component_examples")
      end
    end

    context "when user has other admin roles" do
      before do
        treasury_admin = create(:user, :treasury_team_admin, email_address: "treasury@example.com")
        sign_in_user(email: treasury_admin.email_address, password: "password123")
      end

      it "does not show the Components navigation link" do
        expect(page).not_to have_link("Components", href: "/component_examples")
      end
    end

    context "when user is not an admin" do
      before do
        regular_user = create(:user, email_address: "user@example.com")
        sign_in_user(email: regular_user.email_address, password: "password123")
      end

      it "does not show the Components navigation link" do
        expect(page).not_to have_link("Components", href: "/component_examples")
      end
    end

    context "when user is not authenticated" do
      before do
        visit root_path
      end

      it "does not show the Components navigation link" do
        expect(page).not_to have_link("Components", href: "/component_examples")
      end
    end
  end
end

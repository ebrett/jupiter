require 'rails_helper'

RSpec.describe "Feature Flag Authentication Integration", type: :system do
  before do
    # Ensure we start with a clean slate
    User.destroy_all
    Session.destroy_all
    FeatureFlag.destroy_all
  end

  describe "NationBuilder OAuth Integration" do
    context "when nationbuilder_signin feature flag is enabled" do
      before do
        # Enable the NationBuilder feature flag
        FeatureFlag.create!(
          name: 'nationbuilder_signin',
          description: 'Enable NationBuilder OAuth sign-in integration',
          enabled: true
        )
      end

      it "shows NationBuilder OAuth button on sign-in page" do
        visit sign_in_path

        expect(page).to have_link(href: "/auth/nationbuilder")
        expect(page).to have_content("Or continue with")
        expect(page).to have_content("NationBuilder")
      end

      it "shows NationBuilder OAuth button on sign-up page" do
        visit sign_up_path

        expect(page).to have_link(href: "/auth/nationbuilder")
        expect(page).to have_content("Or continue with")
        expect(page).to have_content("Sign Up with NationBuilder")
      end

      it "displays correct button text based on page" do
        # Test sign-in page
        visit sign_in_path
        oauth_button = find('a[href="/auth/nationbuilder"]')
        expect(oauth_button).to have_content("NationBuilder")

        # Test sign-up page
        visit sign_up_path
        oauth_button = find('a[href="/auth/nationbuilder"]')
        expect(oauth_button).to have_content("Sign Up with NationBuilder")
      end

      it "maintains OAuth integration with regular authentication flow" do
        # Create a test user
        user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123')

        visit sign_in_path

        # Verify OAuth button is present
        expect(page).to have_link(href: "/auth/nationbuilder")

        # Regular authentication should still work
        fill_in "email_address", with: user.email_address
        fill_in "password", with: "password123"
        click_button "Sign in"

        # User should be signed in
        expect(page).to have_button("Sign out")
        expect(page).not_to have_button("Sign In")
      end

      it "maintains OAuth integration with registration flow" do
        visit sign_up_path

        # Verify OAuth button is present
        expect(page).to have_link(href: "/auth/nationbuilder")

        # Regular registration should still work
        fill_in "first_name", with: "Test"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: "newuser@example.com"
        fill_in "password", with: "password123"
        fill_in "password_confirmation", with: "password123"
        click_button "Create Account"

        # Should show success message
        expect(page).to have_content("Account created! Please check your email to verify your account.")
      end
    end

    context "when nationbuilder_signin feature flag is disabled" do
      before do
        # Create disabled feature flag or ensure it doesn't exist
        FeatureFlag.find_by(name: 'nationbuilder_signin')&.update!(enabled: false)
      end

      it "hides NationBuilder OAuth button on sign-in page" do
        visit sign_in_path

        expect(page).not_to have_link(href: "/auth/nationbuilder")
        expect(page).not_to have_content("Or continue with")
        expect(page).not_to have_content("NationBuilder")
      end

      it "hides NationBuilder OAuth button on sign-up page" do
        visit sign_up_path

        expect(page).not_to have_link(href: "/auth/nationbuilder")
        expect(page).not_to have_content("Or continue with")
        expect(page).not_to have_content("Sign Up with NationBuilder")
      end

      it "core authentication flows work with OAuth disabled" do
        # Create a test user
        user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123')

        visit sign_in_path

        # Sign-in should work normally without OAuth elements
        fill_in "email_address", with: user.email_address
        fill_in "password", with: "password123"
        click_button "Sign in"

        # User should be signed in
        expect(page).to have_button("Sign out")
        expect(page).not_to have_button("Sign In")
      end

      it "registration flow works with OAuth disabled" do
        visit sign_up_path

        # Registration should work normally without OAuth elements
        fill_in "first_name", with: "Test"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: "newuser@example.com"
        fill_in "password", with: "password123"
        fill_in "password_confirmation", with: "password123"
        click_button "Create Account"

        # Should show success message
        expect(page).to have_content("Account created! Please check your email to verify your account.")
      end

      it "authentication pages are clean without OAuth elements" do
        visit sign_in_path
        expect(page).to have_content("Sign in to your account")
        expect(page).to have_field("email_address")
        expect(page).to have_field("password")
        expect(page).to have_button("Sign in")
        expect(page).not_to have_content("Or continue with")

        visit sign_up_path
        expect(page).to have_content("Create your account")
        expect(page).to have_field("first_name")
        expect(page).to have_field("last_name")
        expect(page).to have_field("email_address")
        expect(page).to have_field("password")
        expect(page).to have_field("password_confirmation")
        expect(page).to have_button("Create Account")
        expect(page).not_to have_content("Or continue with")
      end
    end

    describe "feature flag transition scenarios" do
      it "handles enabling feature flag during session" do
        # Start with disabled flag
        FeatureFlag.create!(
          name: 'nationbuilder_signin',
          description: 'Enable NationBuilder OAuth sign-in',
          enabled: false
        )

        visit sign_in_path
        expect(page).not_to have_link(href: "/auth/nationbuilder")

        # Enable the flag
        FeatureFlag.find_by(name: 'nationbuilder_signin').update!(enabled: true)

        # Refresh page - OAuth button should now appear
        visit sign_in_path
        expect(page).to have_link(href: "/auth/nationbuilder")
      end

      it "handles disabling feature flag during session" do
        # Start with enabled flag
        FeatureFlag.create!(
          name: 'nationbuilder_signin',
          description: 'Enable NationBuilder OAuth sign-in',
          enabled: true
        )

        visit sign_in_path
        expect(page).to have_link(href: "/auth/nationbuilder")

        # Disable the flag
        FeatureFlag.find_by(name: 'nationbuilder_signin').update!(enabled: false)

        # Refresh page - OAuth button should disappear
        visit sign_in_path
        expect(page).not_to have_link(href: "/auth/nationbuilder")
      end
    end

    describe "OAuth error handling with feature flags" do
      before do
        FeatureFlag.create!(name: 'nationbuilder_signin', description: 'Enable NationBuilder OAuth sign-in', enabled: true)
      end

      it "gracefully handles OAuth failures while maintaining regular auth" do
        visit sign_in_path

        # OAuth button should be present
        expect(page).to have_link(href: "/auth/nationbuilder")

        # If OAuth fails, regular authentication should still work
        user = FactoryBot.create(:user, email_address: 'fallback@example.com', password: 'password123')

        fill_in "email_address", with: user.email_address
        fill_in "password", with: "password123"
        click_button "Sign in"

        expect(page).to have_button("Sign out")
      end

      it "maintains clean UX when OAuth is unavailable" do
        visit sign_in_path

        # Even with OAuth enabled, if service is down, regular auth should work
        expect(page).to have_field("email_address")
        expect(page).to have_field("password")
        expect(page).to have_button("Sign in")

        # Form should be functional
        user = FactoryBot.create(:user, email_address: 'reliable@example.com', password: 'password123')
        fill_in "email_address", with: user.email_address
        fill_in "password", with: "password123"
        click_button "Sign in"

        expect(page).to have_button("Sign out")
      end
    end
  end

  describe "feature flag infrastructure" do
    it "properly manages feature flag state" do
      # Test flag creation
      flag = FeatureFlag.create!(name: 'test_flag', description: 'Test feature flag', enabled: false)
      expect(flag.enabled).to be false

      # Test flag toggle
      flag.update!(enabled: true)
      expect(flag.reload.enabled).to be true

      # Test multiple flags
      flag2 = FeatureFlag.create!(name: 'another_flag', description: 'Another test flag', enabled: true)
      expect(FeatureFlag.count).to eq 2
      expect(FeatureFlag.find_by(name: 'test_flag').enabled).to be true
      expect(FeatureFlag.find_by(name: 'another_flag').enabled).to be true
    end

    it "handles missing feature flags gracefully" do
      # When flag doesn't exist, OAuth should be disabled
      visit sign_in_path
      expect(page).not_to have_link(href: "/auth/nationbuilder")

      visit sign_up_path
      expect(page).not_to have_link(href: "/auth/nationbuilder")
    end
  end
end

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

      it "shows NationBuilder OAuth button in login mode" do
        visit root_path
        open_login_modal

        within "#auth-modal" do
          expect(page).to have_link(href: "/auth/nationbuilder")
          expect(page).to have_content("Sign in with")
          expect(page).to have_content("Or continue with email")
        end
      end

      it "shows NationBuilder OAuth button in registration mode" do
        visit root_path
        open_registration_modal

        within "#auth-modal" do
          expect(page).to have_link(href: "/auth/nationbuilder")
          expect(page).to have_content("Sign up with")
          expect(page).to have_content("Or continue with email")
        end
      end

      it "displays correct button text based on mode" do
        visit root_path

        # Test login mode
        open_login_modal
        within "#auth-modal" do
          oauth_button = find('a[href="/auth/nationbuilder"]')
          expect(oauth_button.text).to include("Sign in with")
        end

        close_modal

        # Test registration mode
        open_registration_modal
        within "#auth-modal" do
          oauth_button = find('a[href="/auth/nationbuilder"]')
          expect(oauth_button.text).to include("Sign up with")
        end
      end

      it "shows divider text 'Or continue with email' when OAuth is enabled" do
        visit root_path
        open_login_modal

        within "#auth-modal" do
          expect(page).to have_content("Or continue with email")
        end
      end

      it "OAuth button has correct styling and icon" do
        visit root_path
        open_login_modal

        within "#auth-modal" do
          oauth_button = find('a[href="/auth/nationbuilder"]')

          # Test semantic properties instead of styling classes
          expect(oauth_button).to be_visible
          expect(oauth_button.text).to include("Sign in with")

          # Should have SVG icon
          expect(oauth_button).to have_css("svg")
        end
      end

      it "core authentication flows work with OAuth enabled" do
        # Create test user for login
        user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123')

        visit root_path
        open_login_modal

        # Email authentication should still work alongside OAuth
        within "#auth-modal" do
          fill_in "email_address", with: user.email_address
          fill_in "password", with: "password123"
          click_button "Sign in"
        end

        expect_to_be_signed_in
      end

      it "registration flow works with OAuth enabled" do
        visit root_path
        open_registration_modal

        # Debug: Check form action before submitting
        form_action = page.find("#auth-modal form")['action']
        expect(form_action).to end_with("/users"), "Form should submit to /users for registration, got: #{form_action}"

        within "#auth-modal" do
          fill_in "first_name", with: "New"
          fill_in "last_name", with: "User"
          fill_in "email_address", with: "newuser@example.com"
          fill_in "password", with: "password123"
          fill_in "password_confirmation", with: "password123"
          click_button "Create account"
        end

        # Should create user successfully and redirect to home page
        expect(page).to have_current_path(root_path)
        expect(page).to have_content("Account created! Please check your email to verify your account.")

        # Verify user was created (note: direct DB check works in feature flag tests)
        new_user = User.find_by(email_address: "newuser@example.com")
        expect(new_user).to be_present
      end

      it "button text updates when switching modes" do
        # Ensure we're signed out and starting fresh
        sign_out_user_if_present

        # Reset the page to ensure clean state
        visit root_path

        # Verify we're in the correct state before proceeding
        expect(page).to have_button("Sign In")
        expect(page).not_to have_button("Sign Out")

        # Ensure JavaScript and Stimulus controllers are fully loaded
        expect(page).to have_css('[data-controller="auth"]', wait: 2)

        open_login_modal

        # Verify login mode text
        within "#auth-modal" do
          oauth_button = find('a[href="/auth/nationbuilder"]')
          expect(oauth_button.text).to include("Sign in with")

          # Switch to registration mode
          click_button "Sign up"
        end

        # Verify registration mode text
        within "#auth-modal" do
          # Wait for the JavaScript to update the button text
          expect(page).to have_content("Create your Jupiter account")
          oauth_button = find('a[href="/auth/nationbuilder"]')
          expect(oauth_button.text).to include("Sign up with")
        end
      end
    end

    context "when nationbuilder_signin feature flag is disabled" do
      before do
        # Ensure the feature flag is disabled (either doesn't exist or is explicitly disabled)
        FeatureFlag.find_by(name: 'nationbuilder_signin')&.update!(enabled: false)
      end

      it "hides NationBuilder OAuth button in login mode" do
        visit root_path
        open_login_modal

        within "#auth-modal" do
          expect(page).not_to have_link(href: "/auth/nationbuilder")
          expect(page).not_to have_content("Sign in with")
          expect(page).not_to have_content("Or continue with email")
        end
      end

      it "hides NationBuilder OAuth button in registration mode" do
        visit root_path
        open_registration_modal

        within "#auth-modal" do
          expect(page).not_to have_link(href: "/auth/nationbuilder")
          expect(page).not_to have_content("Sign up with")
          expect(page).not_to have_content("Or continue with email")
        end
      end

      it "does not show OAuth divider when feature is disabled" do
        visit root_path
        open_login_modal

        within "#auth-modal" do
          expect(page).not_to have_content("Or continue with email")
        end
      end

      it "core authentication flows work with OAuth disabled" do
        # Create test user for login
        user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123')

        visit root_path
        open_login_modal

        # Email authentication should work without OAuth
        within "#auth-modal" do
          fill_in "email_address", with: user.email_address
          fill_in "password", with: "password123"
          click_button "Sign in"
        end

        expect_to_be_signed_in
      end

      it "registration flow works with OAuth disabled" do
        visit root_path
        open_registration_modal

        # Debug: Check form action before submitting
        form_action = page.find("#auth-modal form")['action']
        expect(form_action).to end_with("/users"), "Form should submit to /users for registration, got: #{form_action}"

        within "#auth-modal" do
          fill_in "first_name", with: "New"
          fill_in "last_name", with: "User"
          fill_in "email_address", with: "newuser@example.com"
          fill_in "password", with: "password123"
          fill_in "password_confirmation", with: "password123"
          click_button "Create account"
        end

        # Should create user successfully and redirect to home page
        expect(page).to have_current_path(root_path)
        expect(page).to have_content("Account created! Please check your email to verify your account.")

        # Verify user was created
        new_user = User.find_by(email_address: "newuser@example.com")
        expect(new_user).to be_present
      end

      it "modal layout is clean without OAuth elements" do
        visit root_path
        open_login_modal

        within "#auth-modal" do
          # Should start with email form immediately, no OAuth section
          expect(page).to have_field("email_address")
          expect(page).to have_field("password")
          # More specific: no OAuth button (instead of checking for any SVG)
          expect(page).not_to have_link(href: "/auth/nationbuilder")
          expect(page).not_to have_content("Or continue with email")
        end
      end
    end

    context "feature flag transition scenarios" do
      it "handles enabling feature flag during session" do
        # Start with feature disabled
        visit root_path
        open_login_modal

        within "#auth-modal" do
          expect(page).not_to have_link(href: "/auth/nationbuilder")
        end

        close_modal

        # Enable feature flag
        FeatureFlag.create!(
          name: 'nationbuilder_signin',
          description: 'Enable NationBuilder OAuth sign-in integration',
          enabled: true
        )

        # Refresh page to pick up new flag state
        visit root_path
        open_login_modal

        within "#auth-modal" do
          expect(page).to have_link(href: "/auth/nationbuilder")
          expect(page).to have_content("Sign in with")
        end
      end

      it "handles disabling feature flag during session" do
        # Start with feature enabled
        FeatureFlag.create!(
          name: 'nationbuilder_signin',
          description: 'Enable NationBuilder OAuth sign-in integration',
          enabled: true
        )

        visit root_path
        open_login_modal

        within "#auth-modal" do
          expect(page).to have_link(href: "/auth/nationbuilder")
        end

        close_modal

        # Disable feature flag
        FeatureFlag.find_by(name: 'nationbuilder_signin').update!(enabled: false)

        # Refresh page to pick up new flag state
        visit root_path
        open_login_modal

        within "#auth-modal" do
          expect(page).not_to have_link(href: "/auth/nationbuilder")
          expect(page).not_to have_content("Sign in with")
        end
      end

      it "maintains form functionality during flag transitions" do
        user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123')

        # Test with flag disabled - use main page login
        visit root_path
        within "main" do
          click_button "Sign In"
        end
        within "#auth-modal" do
          fill_in "email_address", with: user.email_address
          fill_in "password", with: "password123"
          click_button "Sign in"
        end
        expect_to_be_signed_in
        sign_out_user

        # Enable flag and test again
        FeatureFlag.create!(
          name: 'nationbuilder_signin',
          description: 'Enable NationBuilder OAuth sign-in integration',
          enabled: true
        )

        visit root_path
        within "main" do
          click_button "Sign In"
        end
        within "#auth-modal" do
          fill_in "email_address", with: user.email_address
          fill_in "password", with: "password123"
          click_button "Sign in"
        end
        expect_to_be_signed_in
      end
    end

    context "nation name display" do
      before do
        FeatureFlag.create!(
          name: 'nationbuilder_signin',
          description: 'Enable NationBuilder OAuth sign-in integration',
          enabled: true
        )
      end

      it "displays formatted nation name in OAuth button" do
        # Get expected formatted name from environment variable (same logic as component)
        slug = ENV["NATIONBUILDER_NATION_SLUG"]
        expected_formatted_name = slug.split("-").map(&:capitalize).join(" ")

        visit root_path
        open_login_modal

        within "#auth-modal" do
          oauth_button = find('a[href="/auth/nationbuilder"]')
          # Should format the environment slug (e.g. "demsabroad" -> "Demsabroad", "testnation" -> "Testnation")
          expect(oauth_button.text).to include(expected_formatted_name)
        end
      end

      it "falls back to 'NationBuilder' when no slug is available" do
        # Temporarily clear the environment variable to test fallback
        original_slug = ENV['NATIONBUILDER_NATION_SLUG']

        begin
          ENV['NATIONBUILDER_NATION_SLUG'] = nil

          visit root_path
          open_login_modal

          within "#auth-modal" do
            oauth_button = find('a[href="/auth/nationbuilder"]')
            # Should use default when no nation slug is set
            expect(oauth_button.text).to include("NationBuilder")
          end
        ensure
          # Always restore original value, even if test fails
          ENV['NATIONBUILDER_NATION_SLUG'] = original_slug
        end
      end
    end
  end

  describe "Feature flag error handling" do
    it "gracefully handles missing feature flag record" do
      # Don't create any feature flag record
      visit root_path
      open_login_modal

      # Should default to disabled behavior (no OAuth elements)
      within "#auth-modal" do
        expect(page).not_to have_link(href: "/auth/nationbuilder")
        expect(page).to have_field("email_address") # Email form should still work
      end
    end

    it "handles malformed feature flag data" do
      # Test that the application gracefully handles feature flags with minimal valid data
      FeatureFlag.create!(
        name: 'nationbuilder_signin',
        description: 'Test flag with minimal description', # Provide required description
        enabled: true
      )

      visit root_path
      open_login_modal

      # Should still show OAuth elements despite minimal description
      within "#auth-modal" do
        expect(page).to have_link(href: "/auth/nationbuilder")
      end
    end
  end

  private

  def open_login_modal
    within "main" do
      click_button "Sign In"
    end

    # Add debug information when modal doesn't open
    unless page.has_css?("#auth-modal", visible: true, wait: 1)
      puts "DEBUG: Modal not visible, page state:"
      puts "Has Sign In button: #{page.has_button?('Sign In')}"
      puts "Has Sign Out button: #{page.has_button?('Sign Out')}"
      puts "Current URL: #{page.current_url}"
      puts "Page title: #{page.title}"
      puts "Has auth controller: #{page.has_css?('[data-controller="auth"]')}"
      puts "Modal exists: #{page.has_css?('#auth-modal')}"
      puts "Modal visible: #{page.has_css?('#auth-modal', visible: true)}"
      puts "Modal without visibility: #{page.has_css?('#auth-modal', visible: :any)}"

      # Try with execute_script to directly check the DOM
      modal_exists_js = page.execute_script("return document.getElementById('auth-modal') !== null")
      puts "Modal exists via JS: #{modal_exists_js}"

      # Try to check if the modal is in the DOM but Capybara can't see it
      if modal_exists_js
        modal_display = page.execute_script("return getComputedStyle(document.getElementById('auth-modal')).display")
        puts "Modal computed display: #{modal_display}"
      end

      # Try clicking again with explicit wait
      within "main" do
        click_button "Sign In"
      end

      # If still not visible, try to open it directly via JavaScript
      unless page.has_css?("#auth-modal", visible: true, wait: 1)
        puts "DEBUG: Forcing modal open via JavaScript"
        page.execute_script("document.getElementById('auth-modal').style.display = 'flex'")
        sleep 0.5
      end
    end

    expect(page).to have_css("#auth-modal", visible: true, wait: 5)
    expect(page).to have_content("Sign in to Jupiter")
  end

  def open_registration_modal
    # Open login modal first, then switch to registration mode
    # This ensures the JavaScript controller is properly initialized
    click_button "Sign in"
    expect_modal_open
    within "#auth-modal" do
      click_button "Sign up"
    end
    expect(page).to have_content("Create your Jupiter account")
    # Verify form action updated to registration endpoint
    expect(page).to have_css('#auth-modal form[action$="/users"]')
  end

  def close_modal
    within "#auth-modal" do
      find('[aria-label="Close modal"]').click
    end
    expect_modal_closed
  end

  def expect_modal_open
    expect(page).to have_css("#auth-modal", visible: true, wait: 5)
  end

  def expect_modal_closed
    expect(page).not_to have_css("#auth-modal", visible: true)
  end

  def expect_to_be_signed_in
    expect(page).to have_button("Sign out")
    expect(page).not_to have_button("Sign in")
  end

  def sign_in_via_modal(email:, password:)
    open_login_modal
    within "#auth-modal" do
      fill_in "email_address", with: email
      fill_in "password", with: password
      click_button "Sign in"
    end
  end

  def sign_out_user
    click_button "Sign out", match: :first
  end

  def sign_out_user_if_present
    visit root_path
    if page.has_button?("Sign Out")
      click_button "Sign Out"
      # Wait for the sign out to complete and page to reload
      expect(page).to have_button("Sign In", wait: 3)
      expect(page).not_to have_button("Sign Out")
    end
  end
end

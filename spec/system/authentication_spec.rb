require 'rails_helper'

RSpec.describe "Authentication System", type: :system do
  before do
    # Ensure we start with a clean slate
    User.destroy_all
    Session.destroy_all
  end

  describe "Sign In Flow" do
    let!(:user) { FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123') }

    context "via login page" do
      it "allows user to sign in with valid credentials" do
        visit new_session_path

        # Verify we're on the login page (not in modal)
        expect(page).to have_content("Sign in")
        expect(page).to have_current_path(new_session_path)

        # Fill in the form on the login page (not in modal)
        within "main" do # Target the main content area to avoid modal
          fill_in "email_address", with: user.email_address
          fill_in "password", with: "password123"
          click_button "Sign in"
        end

        # Verify successful login
        expect_to_be_signed_in
        expect(page).to have_content("Dashboard") # Should redirect to dashboard

        # Verify session was created in database
        expect(Session.where(user: user)).to exist
      end

      it "supports remember me functionality" do
        # Note: Remember me is only available in the auth modal, not the regular login page
        pending "Remember me functionality only available in modal - test in modal context"
      end

      it "shows error for invalid credentials" do
        # Test will be implemented in task 2.7
        pending "Error handling test to be implemented"
      end
    end

    context "via auth modal" do
      it "opens modal and allows sign in" do
        visit root_path

        # Click the "Sign in" button in sidebar to open modal
        click_button "Sign in"

        # Verify modal opened
        expect(page).to have_css("#auth-modal", visible: true)
        expect(page).to have_content("Sign in to Jupiter")

        # Fill in the modal form (using name attributes for form fields)
        within "#auth-modal" do
          fill_in "email_address", with: user.email_address
          fill_in "password", with: "password123"
          click_button "Sign in"
        end

        # Wait for form submission and redirect
        # The modal should close and user should be signed in
        expect_to_be_signed_in

        # Verify session was created
        expect(Session.where(user: user)).to exist
      end

      it "supports remember me functionality in modal" do
        visit root_path

        # Open modal
        click_button "Sign in"
        expect(page).to have_css("#auth-modal", visible: true)

        # Fill in credentials and check remember me
        within "#auth-modal" do
          fill_in "email_address", with: user.email_address
          fill_in "password", with: "password123"
          check "remember_me"
          click_button "Sign in"
        end

        # Verify successful login
        expect_to_be_signed_in

        # Verify session has extended expiration (6 months vs 2 weeks)
        session = Session.find_by(user: user)
        expect(session).to be_present
        expect(session.expires_at).to be > 1.month.from_now
      end
    end
  end

  describe "Registration Flow" do
    context "via registration page" do
      it "allows new user to register with valid information" do
        # Note: No dedicated registration page, only modal registration
        pending "No dedicated registration page - only modal registration available"
      end

      it "shows validation errors for invalid information" do
        # Test will be implemented in task 2.7
        pending "Registration validation test to be implemented"
      end
    end

    context "via auth modal" do
      it "switches to registration mode and creates account" do
        visit root_path

        # Open modal (defaults to login mode)
        click_button "Sign in"
        expect(page).to have_css("#auth-modal", visible: true)
        expect(page).to have_content("Sign in to Jupiter")

        # Switch to registration mode
        within "#auth-modal" do
          click_button "Sign up"
        end

        # Verify modal switched to registration mode
        expect(page).to have_content("Create your Jupiter account")
        expect(page).to have_button("Create account")

        # Fill in registration form
        within "#auth-modal" do
          fill_in "first_name", with: "Test"
          fill_in "last_name", with: "User"
          fill_in "email_address", with: "newuser@example.com"
          fill_in "password", with: "password123"
          fill_in "password_confirmation", with: "password123"
          click_button "Create account"
        end

        # Verify successful registration (but not auto sign-in for email users)
        expect(page).to have_content("Account created! Please check your email to verify your account.")
        expect_to_be_signed_out # Email users need to verify before signing in

        # Verify user was created
        new_user = User.find_by(email_address: "newuser@example.com")
        expect(new_user).to be_present
        expect(new_user.first_name).to eq("Test")
        expect(new_user.last_name).to eq("User")
        expect(new_user.email_password_user?).to be true
      end

      it "opens directly in registration mode when clicked from 'Create account' button" do
        visit root_path

        # Click the "Create account" button in sidebar to open modal in register mode
        click_button "Create account"

        # Verify modal opened in registration mode
        expect(page).to have_css("#auth-modal", visible: true)
        expect(page).to have_content("Create your Jupiter account")
        expect(page).to have_button("Create account")

        # Verify registration fields are visible
        within "#auth-modal" do
          expect(page).to have_field("first_name")
          expect(page).to have_field("last_name")
          expect(page).to have_field("password_confirmation")
        end
      end

      it "can switch back to login mode after opening in registration mode" do
        visit root_path

        # Open modal in registration mode
        click_button "Create account"
        expect(page).to have_content("Create your Jupiter account")

        # Switch back to login mode
        within "#auth-modal" do
          click_button "Sign in"
        end

        # Verify modal switched to login mode
        expect(page).to have_content("Sign in to Jupiter")
        expect(page).to have_button("Sign in")

        # Verify registration-only fields are hidden
        within "#auth-modal" do
          expect(page).not_to have_field("first_name", visible: true)
          expect(page).not_to have_field("last_name", visible: true)
          expect(page).not_to have_field("password_confirmation", visible: true)
        end
      end
    end
  end

  describe "Modal Interactions" do
    it "opens authentication modal via 'Sign in' button" do
      visit root_path

      # Verify modal is initially hidden
      expect(page).not_to have_css("#auth-modal", visible: true)

      # Click sign in button to open modal
      click_button "Sign in"

      # Verify modal opened in login mode
      expect(page).to have_css("#auth-modal", visible: true)
      expect(page).to have_content("Sign in to Jupiter")
      expect(page).to have_button("Sign in")

      # Verify modal contains expected elements
      within "#auth-modal" do
        expect(page).to have_field("email_address")
        expect(page).to have_field("password")
        expect(page).to have_field("remember_me")
      end
    end

    it "opens authentication modal via 'Create account' button" do
      visit root_path

      # Verify modal is initially hidden
      expect(page).not_to have_css("#auth-modal", visible: true)

      # Click create account button to open modal
      click_button "Create account"

      # Verify modal opened in registration mode
      expect(page).to have_css("#auth-modal", visible: true)
      expect(page).to have_content("Create your Jupiter account")
      expect(page).to have_button("Create account")

      # Verify modal contains expected registration elements
      within "#auth-modal" do
        expect(page).to have_field("first_name")
        expect(page).to have_field("last_name")
        expect(page).to have_field("email_address")
        expect(page).to have_field("password")
        expect(page).to have_field("password_confirmation")
      end
    end

    it "switches between login and registration modes" do
      visit root_path

      # Open modal in login mode
      click_button "Sign in"
      expect(page).to have_content("Sign in to Jupiter")

      # Switch to registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Verify switched to registration mode
      expect(page).to have_content("Create your Jupiter account")
      expect(page).to have_button("Create account")

      # Verify registration fields are now visible
      within "#auth-modal" do
        expect(page).to have_field("first_name", visible: true)
        expect(page).to have_field("last_name", visible: true)
        expect(page).to have_field("password_confirmation", visible: true)
        expect(page).not_to have_field("remember_me", visible: true)
      end

      # Switch back to login mode
      within "#auth-modal" do
        click_button "Sign in"
      end

      # Verify switched back to login mode
      expect(page).to have_content("Sign in to Jupiter")
      expect(page).to have_button("Sign in")

      # Verify login fields are visible and registration fields are hidden
      within "#auth-modal" do
        expect(page).not_to have_field("first_name", visible: true)
        expect(page).not_to have_field("last_name", visible: true)
        expect(page).not_to have_field("password_confirmation", visible: true)
        expect(page).to have_field("remember_me", visible: true)
      end
    end

    it "closes modal via close button" do
      visit root_path

      # Open modal
      click_button "Sign in"
      expect(page).to have_css("#auth-modal", visible: true)

      # Close modal using the X button
      within "#auth-modal" do
        find('[aria-label="Close modal"]').click
      end

      # Verify modal is closed
      expect(page).not_to have_css("#auth-modal", visible: true)
    end

    it "closes modal via escape key", :js do
      # JavaScript modal closing requires complex event handling
      # This would be better tested with JavaScript unit tests
      pending "Escape key modal closing requires JavaScript unit testing"
    end

    it "closes modal by clicking outside", :js do
      # JavaScript modal closing requires complex event handling
      # This would be better tested with JavaScript unit tests
      pending "Click-outside modal closing requires JavaScript unit testing"
    end

    it "maintains form data when switching modes" do
      visit root_path

      # Open modal in login mode
      click_button "Sign in"

      # Fill in email (shared field)
      within "#auth-modal" do
        fill_in "email_address", with: "test@example.com"
      end

      # Switch to registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Verify email field retained its value
      within "#auth-modal" do
        expect(page).to have_field("email_address", with: "test@example.com")
      end

      # Fill in additional registration fields
      within "#auth-modal" do
        fill_in "first_name", with: "Test"
        fill_in "password", with: "password123"
      end

      # Switch back to login mode
      within "#auth-modal" do
        click_button "Sign in"
      end

      # Verify shared fields retained their values
      within "#auth-modal" do
        expect(page).to have_field("email_address", with: "test@example.com")
        expect(page).to have_field("password", with: "password123")
      end
    end

    it "properly updates form action when switching modes" do
      visit root_path

      # Open modal in login mode
      click_button "Sign in"

      # Verify form action is for login
      form_action = page.find("#auth-modal form")['action']
      expect(form_action).to end_with("/session")

      # Switch to registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Verify form action changed to registration
      form_action = page.find("#auth-modal form")['action']
      expect(form_action).to end_with("/users")

      # Switch back to login mode
      within "#auth-modal" do
        click_button "Sign in"
      end

      # Verify form action changed back to login
      form_action = page.find("#auth-modal form")['action']
      expect(form_action).to end_with("/session")
    end
  end

  describe "Form Action Verification" do
    it "uses correct form action for login mode" do
      visit root_path

      # Open modal in login mode
      click_button "Sign in"
      expect(page).to have_content("Sign in to Jupiter")

      # Verify form action points to session endpoint
      form_action = page.find("#auth-modal form")['action']
      expect(form_action).to end_with("/session")
      expect(form_action).to match(%r{http://localhost:\d+/session$})
    end

    it "uses correct form action for registration mode" do
      visit root_path

      # Open modal in login mode first, then switch to registration
      # This ensures the Stimulus controller properly updates the form action
      click_button "Sign in"

      within "#auth-modal" do
        click_button "Sign up"
      end

      expect(page).to have_content("Create your Jupiter account")

      # Verify form action points to users endpoint after mode switch
      form_action = page.find("#auth-modal form")['action']
      expect(form_action).to end_with("/users")
      expect(form_action).to match(%r{http://localhost:\d+/users$})
    end

    it "form action changes when switching from login to registration" do
      visit root_path

      # Start in login mode
      click_button "Sign in"
      expect(page.find("#auth-modal form")['action']).to end_with("/session")

      # Switch to registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Verify form action changed
      expect(page.find("#auth-modal form")['action']).to end_with("/users")
    end

    it "form action changes when switching from registration to login" do
      visit root_path

      # Start in login mode, switch to registration, then back to login
      click_button "Sign in"

      within "#auth-modal" do
        click_button "Sign up"
      end
      expect(page.find("#auth-modal form")['action']).to end_with("/users")

      # Switch back to login mode
      within "#auth-modal" do
        click_button "Sign in"
      end

      # Verify form action changed back
      expect(page.find("#auth-modal form")['action']).to end_with("/session")
    end

    it "form method is POST for both login and registration" do
      visit root_path

      # Test login mode
      click_button "Sign in"
      login_method = page.find("#auth-modal form")['method']
      expect(login_method).to eq("post")

      # Switch to registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Test registration mode
      registration_method = page.find("#auth-modal form")['method']
      expect(registration_method).to eq("post")
    end

    it "form has correct data attributes for Stimulus controller" do
      visit root_path

      # Open modal
      click_button "Sign in"

      # Verify form has auth target attribute for Stimulus
      form = page.find("#auth-modal form")
      expect(form['data-auth-target']).to eq("form")
    end

    it "verifies this addresses the original PRD bug about signup redirecting to sign-in" do
      # This test specifically addresses the bug mentioned in the PRD:
      # "Recent issues include the signup form redirecting to sign-in instead of creating accounts
      # due to incorrect form action paths"

      visit root_path

      # Open modal and switch to registration
      click_button "Sign in"
      within "#auth-modal" do
        click_button "Sign up"
      end

      # The critical test: form action must be /users for registration, not /session
      form_action = page.find("#auth-modal form")['action']
      expect(form_action).to end_with("/users"),
        "Registration form should POST to /users, not /session. This was the original bug."
      expect(form_action).not_to end_with("/session"),
        "Registration form must NOT POST to /session as that would cause the reported bug."

      # Additional verification: ensure we're actually in registration mode
      expect(page).to have_content("Create your Jupiter account")
      expect(page).to have_button("Create account")
    end
  end

  describe "Database State Changes" do
    let!(:existing_user) { FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123') }

    it "creates session record on successful login" do
      # Verify no sessions exist initially
      expect(Session.count).to eq(0)

      visit root_path

      # Open modal and sign in
      click_button "Sign in"
      within "#auth-modal" do
        fill_in "email_address", with: existing_user.email_address
        fill_in "password", with: "password123"
        click_button "Sign in"
      end

      # Verify session was created in database
      expect(Session.count).to eq(1)
      session = Session.last
      expect(session.user).to eq(existing_user)
      expect(session.expires_at).to be_present
      expect(session.ip_address).to be_present
      expect(session.user_agent).to be_present
    end

    it "creates user record on successful registration" do
      initial_user_count = User.count

      visit root_path

      # Open modal and register
      click_button "Sign in"
      within "#auth-modal" do
        click_button "Sign up"
        fill_in "first_name", with: "New"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: "newuser@example.com"
        fill_in "password", with: "password123"
        fill_in "password_confirmation", with: "password123"
        click_button "Create account"
      end

      # Verify user was created in database
      expect(User.count).to eq(initial_user_count + 1)
      new_user = User.find_by(email_address: "newuser@example.com")
      expect(new_user).to be_present
      expect(new_user.first_name).to eq("New")
      expect(new_user.last_name).to eq("User")
      expect(new_user.email_password_user?).to be true

      # Note: Email users don't auto-create sessions (need email verification)
      # So we don't expect a session to be created for registration
    end

    it "tracks IP address and user agent in session" do
      visit root_path

      # Sign in to create a session
      click_button "Sign in"
      within "#auth-modal" do
        fill_in "email_address", with: existing_user.email_address
        fill_in "password", with: "password123"
        click_button "Sign in"
      end

      # Verify session tracking data
      session = Session.find_by(user: existing_user)
      expect(session).to be_present

      # IP address should be recorded (test environment uses 127.0.0.1)
      expect(session.ip_address).to be_present
      expect(session.ip_address).to match(/\A\d+\.\d+\.\d+\.\d+\z/) # Basic IP format

      # User agent should be recorded
      expect(session.user_agent).to be_present
      expect(session.user_agent).to include("Chrome") # Capybara uses Chrome driver
    end

    it "creates session with extended expiration when remember me is checked" do
      visit root_path

      # Sign in with remember me checked
      click_button "Sign in"
      within "#auth-modal" do
        fill_in "email_address", with: existing_user.email_address
        fill_in "password", with: "password123"
        check "remember_me"
        click_button "Sign in"
      end

      # Verify session has extended expiration
      session = Session.find_by(user: existing_user)
      expect(session).to be_present
      expect(session.expires_at).to be > 1.month.from_now
    end

    it "creates session with standard expiration when remember me is not checked" do
      visit root_path

      # Sign in without remember me
      click_button "Sign in"
      within "#auth-modal" do
        fill_in "email_address", with: existing_user.email_address
        fill_in "password", with: "password123"
        # Don't check remember_me
        click_button "Sign in"
      end

      # Verify session has standard expiration (should be less than 1 month)
      session = Session.find_by(user: existing_user)
      expect(session).to be_present
      expect(session.expires_at).to be < 1.month.from_now
      expect(session.expires_at).to be > 1.day.from_now # But more than 1 day
    end

    it "destroys session record on sign out" do
      # First sign in to create a session
      visit root_path
      click_button "Sign in"
      within "#auth-modal" do
        fill_in "email_address", with: existing_user.email_address
        fill_in "password", with: "password123"
        click_button "Sign in"
      end

      # Verify session was created
      session = Session.find_by(user: existing_user)
      expect(session).to be_present
      session_id = session.id

      # Sign out
      click_button "Sign out", match: :first

      # Verify session was destroyed
      expect(Session.find_by(id: session_id)).to be_nil
      expect(Session.where(user: existing_user)).to be_empty
    end
  end

  describe "Sign Out Flow" do
    let!(:user) { FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123') }

    it "allows user to sign out" do
      # First sign in
      sign_in_user(email: user.email_address, password: "password123")
      expect_to_be_signed_in

      # Click sign out button
      click_button "Sign out", match: :first

      # Verify user is signed out
      expect_to_be_signed_out
      expect(page).to have_button("Sign in") # Should see login button again
    end

    it "destroys session on sign out" do
      # First sign in
      sign_in_user(email: user.email_address, password: "password123")

      # Verify session was created
      session = Session.find_by(user: user)
      expect(session).to be_present
      session_id = session.id

      # Sign out
      click_button "Sign out", match: :first

      # Verify session is destroyed
      expect(Session.find_by(id: session_id)).to be_nil
    end
  end

  describe "Error Handling" do
    it "displays appropriate error messages for invalid login" do
      visit root_path

      # Open modal and attempt login with invalid credentials
      click_button "Sign in"
      within "#auth-modal" do
        fill_in "email_address", with: "nonexistent@example.com"
        fill_in "password", with: "wrongpassword"
        click_button "Sign in"
      end

      # Verify error message is displayed
      expect(page).to have_content("Invalid email or password")

      # Verify modal stays open to allow retry
      expect(page).to have_css("#auth-modal", visible: true)
      expect(page).to have_content("Sign in to Jupiter")
    end

    it "displays error for empty login fields" do
      visit root_path

      # Open modal and attempt login with empty fields
      click_button "Sign in"
      within "#auth-modal" do
        # Leave fields empty
        click_button "Sign in"
      end

      # Browser validation should prevent submission, but if it gets through:
      # Verify form validation or error message
      expect(page).to have_css("#auth-modal", visible: true) # Modal should stay open
    end

    it "displays validation errors for invalid registration" do
      visit root_path

      # Open modal and switch to registration
      click_button "Sign in"
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Attempt registration with invalid data (short password)
      within "#auth-modal" do
        fill_in "first_name", with: "Test"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: "test@example.com"
        fill_in "password", with: "123" # Too short
        fill_in "password_confirmation", with: "123"
        click_button "Create account"
      end

      # Verify password validation error
      expect(page).to have_content("Password is too short")

      # Verify modal stays open for retry
      expect(page).to have_css("#auth-modal", visible: true)
      expect(page).to have_content("Create your Jupiter account")
    end

    it "displays error for mismatched password confirmation" do
      visit root_path

      # Open modal and switch to registration
      click_button "Sign in"
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Attempt registration with mismatched passwords
      within "#auth-modal" do
        fill_in "first_name", with: "Test"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: "test@example.com"
        fill_in "password", with: "password123"
        fill_in "password_confirmation", with: "differentpassword"
        click_button "Create account"
      end

      # Verify password confirmation error
      expect(page).to have_content("Password confirmation doesn't match")

      # Verify modal stays open for retry
      expect(page).to have_css("#auth-modal", visible: true)
    end

    it "displays error for duplicate email registration" do
      # Create existing user
      existing_user = FactoryBot.create(:user, email_address: 'existing@example.com')

      visit root_path

      # Open modal and switch to registration
      click_button "Sign in"
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Attempt registration with existing email
      within "#auth-modal" do
        fill_in "first_name", with: "Test"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: existing_user.email_address
        fill_in "password", with: "password123"
        fill_in "password_confirmation", with: "password123"
        click_button "Create account"
      end

      # Verify email uniqueness error
      expect(page).to have_content("Email address has already been taken")

      # Verify modal stays open for retry
      expect(page).to have_css("#auth-modal", visible: true)
    end

    it "handles form submission errors gracefully" do
      visit root_path

      # Open modal
      click_button "Sign in"

      # Test network/server error scenarios by submitting form with invalid data
      within "#auth-modal" do
        fill_in "email_address", with: "invalid-email-format"
        fill_in "password", with: "password123"
        click_button "Sign in"
      end

      # Verify error handling (either validation error or server error)
      # Form should either show validation error or handle server error gracefully
      expect(page).to have_css("#auth-modal", visible: true) # Modal should remain open

      # Additional verification that form is still functional
      within "#auth-modal" do
        expect(page).to have_field("email_address")
        expect(page).to have_field("password")
        expect(page).to have_button("Sign in")
      end
    end

    it "preserves form data when validation errors occur" do
      visit root_path

      # Open modal and switch to registration
      click_button "Sign in"
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Fill form with some valid and some invalid data
      within "#auth-modal" do
        fill_in "first_name", with: "Valid"
        fill_in "last_name", with: "Name"
        fill_in "email_address", with: "valid@example.com"
        fill_in "password", with: "123" # Too short - will cause validation error
        fill_in "password_confirmation", with: "123"
        click_button "Create account"
      end

      # After validation error, verify valid data is preserved
      within "#auth-modal" do
        expect(page).to have_field("first_name", with: "Valid")
        expect(page).to have_field("last_name", with: "Name")
        expect(page).to have_field("email_address", with: "valid@example.com")
        # Password fields are typically cleared for security
      end
    end
  end

  describe "NationBuilder OAuth Integration" do
    context "when feature flag is enabled" do
      it "shows NationBuilder sign-in button" do
        # This will be covered in task 5.0 (feature flag tests)
        pending "OAuth button visibility test to be implemented"
      end
    end

    context "when feature flag is disabled" do
      it "hides NationBuilder sign-in button" do
        # This will be covered in task 5.0 (feature flag tests)
        pending "OAuth button hiding test to be implemented"
      end
    end
  end

  private

  def sign_in_user(email:, password:)
    # Helper method for signing in via login page
    visit new_session_path
    within "main" do
      fill_in "email_address", with: email
      fill_in "password", with: password
      click_button "Sign in"
    end
  end

  def open_auth_modal
    # Helper method for opening the auth modal from homepage
    visit root_path
    click_button "Sign in"
    expect(page).to have_css("#auth-modal", visible: true)
  end

  def expect_to_be_signed_in
    # Helper method to verify user is signed in
    # Look for user-specific elements that only appear when authenticated
    expect(page).to have_button("Sign out") # Logout button in sidebar
    expect(page).not_to have_button("Sign in") # No login button when authenticated
  end

  def expect_to_be_signed_out
    # Helper method to verify user is signed out
    # Look for login/signup buttons that only appear when not authenticated
    expect(page).to have_button("Sign in") # Login button in sidebar
    expect(page).to have_button("Create account") # Signup button in sidebar
    expect(page).not_to have_button("Sign out") # No logout button when not authenticated
  end
end

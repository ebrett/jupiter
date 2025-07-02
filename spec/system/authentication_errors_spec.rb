require 'rails_helper'

RSpec.describe "Authentication Errors", type: :system do
  before do
    # Ensure we start with a clean slate
    User.destroy_all
    Session.destroy_all
  end

  describe "Login Error Handling" do
    it "displays appropriate error messages for invalid login" do
      visit root_path

      # Open modal and attempt login with invalid credentials
      open_login_modal
      within "#auth-modal" do
        fill_in "email_address", with: "nonexistent@example.com"
        fill_in "password", with: "wrongpassword"
        find('input[type="submit"]').click
      end

      # The current implementation redirects to login page with flash message
      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("Try another email address or password.")

      # Verify we're on the login page showing the error
      expect(page).to have_content("Sign in")
      expect(page).to have_field("email_address")
    end

    it "displays error for empty login fields" do
      visit root_path

      # Open modal and attempt login with empty fields
      open_login_modal
      within "#auth-modal" do
        # Leave fields empty and submit (bypassing browser validation for testing)
        page.execute_script("document.querySelector('#auth-modal form').noValidate = true;")
        find('input[type="submit"]').click
      end

      # The current implementation redirects to login page with flash message
      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("Try another email address or password.")
    end

    it "handles form submission errors gracefully" do
      visit root_path

      # Open modal
      open_login_modal

      # Test form submission with invalid email format
      within "#auth-modal" do
        fill_in "email_address", with: "invalid-email-format"
        fill_in "password", with: "password123"
        find('input[type="submit"]').click
      end

      # The form should fail with either browser validation or server error
      # Since invalid email format might be caught by browser validation or server
      if page.has_current_path?(new_session_path)
        # Server handled it - redirected with error
        expect(page).to have_content("Try another email address or password.")
        expect(page).to have_field("email_address")
      else
        # Browser validation or stayed on same page
        expect(page).to have_current_path(root_path)
        # Check if modal is still open or if there's an error message
      end
    end

    it "shows error for non-existent user" do
      visit root_path

      # Open modal and attempt login with non-existent user
      open_login_modal
      within "#auth-modal" do
        fill_in "email_address", with: "doesnotexist@example.com"
        fill_in "password", with: "anypassword"
        find('input[type="submit"]').click
      end

      # Should redirect with error message
      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("Try another email address or password.")
    end

    it "shows error for correct email but wrong password" do
      # Create a user first
      user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'correctpassword', password_confirmation: 'correctpassword')

      visit root_path

      # Open modal and attempt login with wrong password
      open_login_modal
      within "#auth-modal" do
        fill_in "email_address", with: user.email_address
        fill_in "password", with: "wrongpassword"
        find('input[type="submit"]').click
      end

      # Should redirect with error message
      expect(page).to have_current_path(new_session_path)
      expect(page).to have_content("Try another email address or password.")
    end
  end

  describe "Registration Error Handling" do
    it "displays validation errors for invalid registration" do
      visit root_path

      # Open modal and switch to registration
      open_login_modal
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
        find('input[type="submit"]').click
      end

      # The current implementation redirects to home page with flash message
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Registration failed:")
      expect(page).to have_content("Password is too short")
    end

    it "displays error for mismatched password confirmation" do
      visit root_path

      # Open modal and switch to registration
      open_login_modal
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
        find('input[type="submit"]').click
      end

      # The current implementation redirects to home page with flash message
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Registration failed:")
      expect(page).to have_content("Password confirmation doesn't match")
    end

    it "displays error for duplicate email registration" do
      # Create existing user
      existing_user = FactoryBot.create(:user, email_address: 'existing@example.com')

      visit root_path

      # Open modal and switch to registration
      open_login_modal
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
        find('input[type="submit"]').click
      end

      # The current implementation redirects to home page with flash message
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Registration failed:")
      expect(page).to have_content("Email address has already been taken")
    end

    it "shows validation errors after failed registration" do
      visit root_path

      # Open modal and switch to registration
      open_login_modal
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Fill form with invalid data (short password)
      within "#auth-modal" do
        fill_in "first_name", with: "Valid"
        fill_in "last_name", with: "Name"
        fill_in "email_address", with: "valid@example.com"
        fill_in "password", with: "123" # Too short - will cause validation error
        fill_in "password_confirmation", with: "123"
        find('input[type="submit"]').click
      end

      # After validation error, user is redirected to home page with error message
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Registration failed:")
      expect(page).to have_content("Password is too short")

      # User can try again by clicking the registration button
      expect(page).to have_button("Create Account")
    end

    it "displays error for missing required fields" do
      visit root_path

      # Open modal and switch to registration
      open_login_modal
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Attempt registration with missing required fields
      within "#auth-modal" do
        fill_in "first_name", with: ""
        fill_in "last_name", with: ""
        fill_in "email_address", with: ""
        fill_in "password", with: ""
        fill_in "password_confirmation", with: ""

        # Bypass browser validation for testing
        page.execute_script("document.querySelector('#auth-modal form').noValidate = true;")
        find('input[type="submit"]').click
      end

      # Should show validation errors
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Registration failed:")
      # Could show various "can't be blank" messages
    end

    it "displays error for invalid email format" do
      visit root_path

      # Open modal and switch to registration
      open_login_modal
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Attempt registration with empty email
      within "#auth-modal" do
        fill_in "first_name", with: "Test"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: ""
        fill_in "password", with: "password123"
        fill_in "password_confirmation", with: "password123"

        # Bypass browser validation to test server validation
        page.execute_script("document.querySelector('#auth-modal form').noValidate = true;")
        find('input[type="submit"]').click
      end

      # Should show validation error on the same page
      expect(page).to have_current_path(root_path)
      expect(page).to have_content("Registration failed: Email address can't be blank")
    end
  end

  describe "General Error Handling" do
    it "handles network errors gracefully" do
      visit root_path

      # This test would require mocking network failures
      # For now, we'll skip it as it requires advanced testing setup
      skip "Network error testing requires advanced mocking setup"
    end

    it "handles server errors gracefully" do
      visit root_path

      # This test would require simulating server errors
      # For now, we'll skip it as it requires advanced testing setup
      skip "Server error testing requires advanced mocking setup"
    end

    it "provides clear error messaging" do
      visit root_path

      # Test that error messages are user-friendly
      open_login_modal
      within "#auth-modal" do
        fill_in "email_address", with: "nonexistent@example.com"
        fill_in "password", with: "wrongpassword"
        find('input[type="submit"]').click
      end

      # Error message should be clear and actionable
      expect(page).to have_content("Try another email address or password.")
      expect(page).not_to have_content("500 Internal Server Error")
      expect(page).not_to have_content("undefined method")
    end

    it "maintains modal state during error conditions" do
      visit root_path

      # Open modal
      open_login_modal
      expect(page).to have_css("#auth-modal", visible: true)

      # Switch to registration and trigger an error
      within "#auth-modal" do
        click_button "Sign up"
        fill_in "password", with: "123" # Too short
        fill_in "password_confirmation", with: "123"
        find('input[type="submit"]').click
      end

      # After error, user should be able to access the form again
      expect(page).to have_button("Create account") # Can retry registration
    end

    it "clears previous error messages when modal is reopened" do
      visit root_path

      # Trigger an error
      open_login_modal
      within "#auth-modal" do
        fill_in "email_address", with: "bad@example.com"
        fill_in "password", with: "wrongpassword"
        find('input[type="submit"]').click
      end

      # Should see error
      expect(page).to have_content("Try another email address or password.")

      # Go back to home page and open modal again
      visit root_path
      open_login_modal

      # Previous error should not be shown
      expect(page).not_to have_content("Try another email address or password.")
      expect(page).to have_css("#auth-modal", visible: true)
    end
  end

  describe "Error Recovery" do
    it "allows user to retry after login error" do
      # Create a valid user
      user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123')

      visit root_path

      # Try invalid login first
      open_login_modal
      within "#auth-modal" do
        fill_in "email_address", with: user.email_address
        fill_in "password", with: "wrongpassword"
        find('input[type="submit"]').click
      end

      # Should get error
      expect(page).to have_content("Try another email address or password.")

      # Now try with correct credentials
      within "main" do
        fill_in "email_address", with: user.email_address
        fill_in "password", with: "password123"
        find('input[type="submit"]').click
      end

      # Should succeed
      expect_to_be_signed_in
    end

    it "allows user to retry after registration error" do
      visit root_path

      # Try invalid registration first
      open_login_modal
      within "#auth-modal" do
        click_button "Sign up"
        fill_in "first_name", with: "Test"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: "test@example.com"
        fill_in "password", with: "123" # Too short
        fill_in "password_confirmation", with: "123"
        find('input[type="submit"]').click
      end

      # Should show error - either on page or in modal
      if page.has_current_path?(root_path)
        expect(page).to have_content("Registration failed")
        expect(page).to have_content("Password is too short")
      else
        # Modal might still be open showing validation
        expect(page).to have_css("#auth-modal", visible: true)
      end

      # Try again with valid data - need to reopen modal by clicking "Sign in"
      open_login_modal
      within "#auth-modal" do
        click_button "Sign up"
        fill_in "first_name", with: "Test"
        fill_in "last_name", with: "User"
        fill_in "email_address", with: "newuser@example.com"
        fill_in "password", with: "password123"
        fill_in "password_confirmation", with: "password123"
        find('input[type="submit"]').click
      end

      # Should succeed
      expect(page).to have_content("Account created! Please check your email to verify your account.")
    end
  end

  private

  def expect_to_be_signed_in
    # Helper method to verify user is signed in
    expect(page).to have_button("Sign out")
    expect(page).not_to have_button("Sign in")
  end
end

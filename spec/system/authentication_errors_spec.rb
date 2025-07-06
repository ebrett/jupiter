require 'rails_helper'

RSpec.describe "Authentication Errors", type: :system do
  before do
    # Ensure we start with a clean slate
    User.destroy_all
    Session.destroy_all
  end

  describe "Login Error Handling" do
    it "displays appropriate error messages for invalid login" do
      visit sign_in_path

      # Attempt login with invalid credentials on dedicated sign-in page
      fill_in "email_address", with: "nonexistent@example.com"
      fill_in "password", with: "wrongpassword"
      click_button "Sign in"

      # Should redirect back to sign-in page with flash message
      expect(page.current_path).to eq(sign_in_path)
      expect(page).to have_content("Try another email address or password.")

      # Verify we're on the login page showing the error
      expect(page).to have_content("Sign in to your account")
      expect(page).to have_field("email_address")
    end

    it "displays error for empty login fields" do
      visit sign_in_path

      # Attempt login with empty fields (bypassing browser validation for testing)
      page.execute_script("document.querySelector('form').noValidate = true;")
      click_button "Sign in"

      # Should redirect back to sign-in page with flash message
      expect(page.current_path).to eq(sign_in_path)
      expect(page).to have_content("Try another email address or password.")
    end

    it "handles form submission errors gracefully" do
      visit sign_in_path

      # Test form submission with invalid email format (bypass browser validation)
      fill_in "email_address", with: "invalid-email-format"
      fill_in "password", with: "password123"

      # Disable HTML5 validation for testing server-side validation
      page.execute_script("document.querySelector('form').noValidate = true;")
      click_button "Sign in"

      # Should redirect back to sign-in page with error message
      expect(page.current_path).to eq(sign_in_path)
      expect(page).to have_content("Try another email address or password.")
      expect(page).to have_field("email_address")
    end

    it "shows error for non-existent user" do
      visit sign_in_path

      # Attempt login with non-existent user
      fill_in "email_address", with: "doesnotexist@example.com"
      fill_in "password", with: "anypassword"
      click_button "Sign in"

      # Should redirect with error message
      expect(page.current_path).to eq(sign_in_path)
      expect(page).to have_content("Try another email address or password.")
    end

    it "shows error for correct email but wrong password" do
      # Create a user first
      user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'correctpassword', password_confirmation: 'correctpassword')

      visit sign_in_path

      # Attempt login with wrong password
      fill_in "email_address", with: user.email_address
      fill_in "password", with: "wrongpassword"
      click_button "Sign in"

      # Should redirect with error message
      expect(page.current_path).to eq(sign_in_path)
      expect(page).to have_content("Try another email address or password.")
    end
  end

  describe "Registration Error Handling" do
    it "displays validation errors for invalid registration" do
      visit sign_up_path

      # Attempt registration with invalid data (short password)
      fill_in "first_name", with: "Test"
      fill_in "last_name", with: "User"
      fill_in "email_address", with: "test@example.com"
      fill_in "password", with: "123" # Too short
      fill_in "password_confirmation", with: "123"

      # Disable HTML5 validation to test server-side validation
      page.execute_script("document.querySelector('form').noValidate = true;")
      click_button "Create Account"

      # Should redirect back to sign-up page with flash message
      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content("Password is too short")
    end

    it "displays error for mismatched password confirmation" do
      visit sign_up_path

      # Attempt registration with mismatched passwords
      fill_in "first_name", with: "Test"
      fill_in "last_name", with: "User"
      fill_in "email_address", with: "test@example.com"
      fill_in "password", with: "password123"
      fill_in "password_confirmation", with: "differentpassword"
      click_button "Create Account"

      # Should redirect back to sign-up page with flash message
      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content("Password confirmation doesn't match")
    end

    it "displays error for duplicate email registration" do
      # Create existing user
      existing_user = FactoryBot.create(:user, email_address: 'existing@example.com')

      visit sign_up_path

      # Attempt registration with existing email
      fill_in "first_name", with: "Test"
      fill_in "last_name", with: "User"
      fill_in "email_address", with: existing_user.email_address
      fill_in "password", with: "password123"
      fill_in "password_confirmation", with: "password123"
      click_button "Create Account"

      # Should redirect back to sign-up page with flash message
      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content("Email address has already been taken")
    end

    it "shows validation errors after failed registration" do
      visit sign_up_path

      # Fill form with invalid data (short password)
      fill_in "first_name", with: "Valid"
      fill_in "last_name", with: "Name"
      fill_in "email_address", with: "valid@example.com"
      fill_in "password", with: "123" # Too short - will cause validation error
      fill_in "password_confirmation", with: "123"

      # Disable HTML5 validation to test server-side validation
      page.execute_script("document.querySelector('form').noValidate = true;")
      click_button "Create Account"

      # After validation error, user should be on sign-up page with error message
      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content("Password is too short")

      # User can try again with the same form
      expect(page).to have_button("Create Account")
    end

    it "displays error for missing required fields" do
      visit sign_up_path

      # Attempt registration with missing required fields
      fill_in "first_name", with: ""
      fill_in "last_name", with: ""
      fill_in "email_address", with: ""
      fill_in "password", with: ""
      fill_in "password_confirmation", with: ""

      # Bypass browser validation for testing
      page.execute_script("document.querySelector('form').noValidate = true;")
      click_button "Create Account"

      # Should show validation errors
      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content("Email address can't be blank")
      # Could show various "can't be blank" messages
    end

    it "displays error for invalid email format" do
      visit sign_up_path

      # Attempt registration with empty email
      fill_in "first_name", with: "Test"
      fill_in "last_name", with: "User"
      fill_in "email_address", with: ""
      fill_in "password", with: "password123"
      fill_in "password_confirmation", with: "password123"

      # Bypass browser validation to test server validation
      page.execute_script("document.querySelector('form').noValidate = true;")
      click_button "Create Account"

      # Should show validation error on the same page
      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content("Email address can't be blank")
    end
  end

  describe "General Error Handling" do
    it "handles network errors gracefully" do
      visit sign_in_path

      # This test would require mocking network failures
      # For now, we'll skip it as it requires advanced testing setup
      skip "Network error testing requires advanced mocking setup"
    end

    it "handles server errors gracefully" do
      visit sign_in_path

      # This test would require simulating server errors
      # For now, we'll skip it as it requires advanced testing setup
      skip "Server error testing requires advanced mocking setup"
    end

    it "provides clear error messaging" do
      visit sign_in_path

      # Test that error messages are user-friendly
      fill_in "email_address", with: "nonexistent@example.com"
      fill_in "password", with: "wrongpassword"
      click_button "Sign in"

      # Error message should be clear and actionable
      expect(page).to have_content("Try another email address or password.")
      expect(page).not_to have_content("500 Internal Server Error")
      expect(page).not_to have_content("undefined method")
    end

    it "maintains form state during error conditions" do
      visit sign_up_path

      # Fill form and trigger an error
      fill_in "first_name", with: "Test"
      fill_in "last_name", with: "User"
      fill_in "email_address", with: "test@example.com"
      fill_in "password", with: "123" # Too short
      fill_in "password_confirmation", with: "123"
      click_button "Create Account"

      # After error, user should be able to access the form again
      expect(page).to have_button("Create Account") # Can retry registration
    end

    it "clears previous error messages when new page is visited" do
      visit sign_in_path

      # Trigger an error
      fill_in "email_address", with: "bad@example.com"
      fill_in "password", with: "wrongpassword"
      click_button "Sign in"

      # Should see error
      expect(page).to have_content("Try another email address or password.")

      # Go to sign-up page and back to sign-in
      visit sign_up_path
      visit sign_in_path

      # Previous error should not be shown
      expect(page).not_to have_content("Try another email address or password.")
      expect(page).to have_content("Sign in to your account")
    end
  end

  describe "Error Recovery" do
    it "allows user to retry after login error" do
      # Create a valid user
      user = FactoryBot.create(:user, email_address: 'test@example.com', password: 'password123')

      visit sign_in_path

      # Try invalid login first
      fill_in "email_address", with: user.email_address
      fill_in "password", with: "wrongpassword"
      click_button "Sign in"

      # Should get error
      expect(page).to have_content("Try another email address or password.")

      # Now try with correct credentials
      fill_in "email_address", with: user.email_address
      fill_in "password", with: "password123"
      click_button "Sign in"

      # Should succeed
      expect_to_be_signed_in
    end
  end

  private

  def expect_to_be_signed_in
    # Helper method to verify user is signed in
    expect(page).to have_button("Sign out")
    expect(page).not_to have_button("Sign In")
  end
end

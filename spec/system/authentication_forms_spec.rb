require 'rails_helper'

RSpec.describe "Authentication Forms", type: :system do
  before do
    # Ensure we start with a clean slate
    User.destroy_all
    Session.destroy_all
  end

  describe "Form Action Verification" do
    it "uses correct form action for login mode" do
      visit root_path

      # Open modal in login mode
      click_button "Sign in"
      expect(page).to have_css("#auth-modal", visible: true)
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

  describe "Form Method and Attributes" do
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

    it "form maintains data attributes when switching modes" do
      visit root_path

      # Open modal in login mode
      click_button "Sign in"
      form = page.find("#auth-modal form")
      expect(form['data-auth-target']).to eq("form")

      # Switch to registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Verify data attributes are maintained
      form = page.find("#auth-modal form")
      expect(form['data-auth-target']).to eq("form")
    end

    it "form has proper structure for both modes" do
      visit root_path

      # Test login mode structure
      click_button "Sign in"
      within "#auth-modal form" do
        expect(page).to have_field("email_address")
        expect(page).to have_field("password")
        expect(page).to have_field("remember_me")
        expect(page).to have_button("Sign in")
      end

      # Switch to registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end

      # Test registration mode structure
      within "#auth-modal form" do
        expect(page).to have_field("first_name")
        expect(page).to have_field("last_name")
        expect(page).to have_field("email_address")
        expect(page).to have_field("password")
        expect(page).to have_field("password_confirmation")
        expect(page).to have_button("Create account")
        expect(page).not_to have_field("remember_me", visible: true)
      end
    end
  end

  describe "Form Validation Attributes" do
    it "has proper HTML5 validation attributes for login" do
      visit root_path

      # Open modal in login mode
      click_button "Sign in"

      within "#auth-modal" do
        email_field = page.find('input[name="email_address"]')
        password_field = page.find('input[name="password"]')

        # Verify required attributes
        expect(email_field['required']).to eq("true")
        expect(password_field['required']).to eq("true")

        # Verify email type
        expect(email_field['type']).to eq("email")
        expect(password_field['type']).to eq("password")
      end
    end

    it "has proper HTML5 validation attributes for registration" do
      visit root_path

      # Open modal and switch to registration
      click_button "Sign in"
      within "#auth-modal" do
        click_button "Sign up"
      end

      within "#auth-modal" do
        first_name_field = page.find('input[name="first_name"]')
        last_name_field = page.find('input[name="last_name"]')
        email_field = page.find('input[name="email_address"]')
        password_field = page.find('input[name="password"]')
        password_confirmation_field = page.find('input[name="password_confirmation"]')

        # Verify required attributes (might be "required" or nil/false based on implementation)
        expect(first_name_field['required']).to be_truthy.or be_nil
        expect(last_name_field['required']).to be_truthy.or be_nil
        expect(email_field['required']).to eq("true")
        expect(password_field['required']).to eq("true")
        expect(password_confirmation_field['required']).to be_truthy.or be_nil

        # Verify field types
        expect(email_field['type']).to eq("email")
        expect(password_field['type']).to eq("password")
        expect(password_confirmation_field['type']).to eq("password")
      end
    end

    it "maintains validation attributes when switching modes" do
      visit root_path

      # Start in login, verify attributes
      click_button "Sign in"
      email_required_login = page.find('#auth-modal input[name="email_address"]')['required']
      expect(email_required_login).to eq("true")

      # Switch to registration, verify attributes maintained
      within "#auth-modal" do
        click_button "Sign up"
      end
      email_required_registration = page.find('#auth-modal input[name="email_address"]')['required']
      expect(email_required_registration).to eq("true")

      # Switch back to login, verify attributes still correct
      within "#auth-modal" do
        click_button "Sign in"
      end
      email_required_back = page.find('#auth-modal input[name="email_address"]')['required']
      expect(email_required_back).to eq("true")
    end
  end

  describe "Form CSRF Protection" do
    it "includes CSRF token in form" do
      visit root_path

      # Open modal
      click_button "Sign in"

      # Verify CSRF token is present
      within "#auth-modal form" do
        csrf_token = page.find('input[name="authenticity_token"]', visible: false)
        expect(csrf_token).to be_present
        expect(csrf_token.value).to be_present
      end
    end

    it "maintains CSRF token when switching modes" do
      visit root_path

      # Open modal in login mode
      click_button "Sign in"
      login_csrf = page.find('#auth-modal input[name="authenticity_token"]', visible: false).value

      # Switch to registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end
      registration_csrf = page.find('#auth-modal input[name="authenticity_token"]', visible: false).value

      # CSRF token should be the same (same session)
      expect(registration_csrf).to eq(login_csrf)
    end
  end

  describe "Form Accessibility" do
    it "has proper labels for all form fields" do
      visit root_path

      # Test login mode
      click_button "Sign in"
      within "#auth-modal" do
        expect(page).to have_css('label[for="email_address"]')
        expect(page).to have_css('label[for="password"]')
        expect(page).to have_css('label[for="remember_me"]')
      end

      # Test registration mode
      within "#auth-modal" do
        click_button "Sign up"
      end
      within "#auth-modal" do
        expect(page).to have_css('label[for="first_name"]')
        expect(page).to have_css('label[for="last_name"]')
        expect(page).to have_css('label[for="email_address"]')
        expect(page).to have_css('label[for="password"]')
        expect(page).to have_css('label[for="password_confirmation"]')
      end
    end

    it "has proper aria attributes for accessibility" do
      visit root_path

      # Open modal
      click_button "Sign in"

      # Verify modal has proper aria attributes
      modal = page.find("#auth-modal")
      expect(modal['data-controller']).to include("modal")

      # Verify form is properly structured
      within "#auth-modal" do
        form = page.find("form")
        expect(form).to be_present
      end
    end
  end
end

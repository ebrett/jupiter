# System Test Helper Methods
#
# This module provides reusable helper methods for system tests,
# particularly for authentication flows and modal interactions.
#
module SystemTestHelpers
  # Authentication Helper Methods

  def sign_in_user(email:, password:, remember_me: false)
    """Sign in a user via the login page (not modal)"""
    visit new_session_path
    within "main" do
      fill_in "email_address", with: email
      fill_in "password", with: password
      check "remember_me" if remember_me
      find('input[type="submit"]').click
    end
  end

  def sign_in_via_modal(email:, password:, remember_me: false)
    """Sign in a user via the authentication modal"""
    visit root_path unless current_path == root_path
    open_login_modal

    within "#auth-modal" do
      fill_in "email_address", with: email
      fill_in "password", with: password
      check "remember_me" if remember_me
      find('input[type="submit"]').click
    end
  end

  def register_user_via_modal(first_name:, last_name:, email:, password:, password_confirmation: nil)
    """Register a new user via the authentication modal"""
    password_confirmation ||= password

    visit root_path unless current_path == root_path
    open_registration_modal

    within "#auth-modal" do
      fill_in "first_name", with: first_name
      fill_in "last_name", with: last_name
      fill_in "email_address", with: email
      fill_in "password", with: password
      fill_in "password_confirmation", with: password_confirmation
      find('input[type="submit"]').click
    end
  end

  def create_authenticated_user(email: "testuser@example.com", password: "password123")
    """Create a user and sign them in, returning the user object"""
    user = FactoryBot.create(:user, email_address: email, password: password)
    sign_in_user(email: email, password: password)
    user
  end

  def sign_out_user
    """Sign out the current user"""
    click_button "Sign out", match: :first
  end

  # Modal Interaction Helper Methods

  def open_login_modal
    """Open the authentication modal in login mode"""
    # Use main content area to avoid sidebar confusion
    within "main" do
      click_button "Sign In"
    end
    # Wait for modal to be visible with reduced timeout
    expect(page).to have_css("#auth-modal", visible: true, wait: 2)
    # Wait for modal content to load
    expect(page).to have_content("Sign in to Jupiter", wait: 1)
    # Ensure Stimulus controller is initialized
    expect(page).to have_css("#auth-modal form", wait: 1)
  end

  def open_registration_modal
    """Open the authentication modal in registration mode"""
    # Use main content area to avoid sidebar confusion
    within "main" do
      click_button "Create Account"
    end
    # Wait for modal to be visible with reduced timeout
    expect(page).to have_css("#auth-modal", visible: true, wait: 2)
    # Wait for modal content to load
    expect(page).to have_content("Create your Jupiter account", wait: 1)
    # Ensure form is ready
    expect(page).to have_css("#auth-modal form", wait: 1)
  end

  def open_auth_modal
    """Open the authentication modal (defaults to login mode)"""
    open_login_modal
  end

  def close_modal
    """Close the authentication modal using the close button"""
    within "#auth-modal" do
      find('[aria-label="Close modal"]').click
    end
    expect_modal_closed
  end

  def switch_to_login_mode
    """Switch the modal from registration to login mode"""
    within "#auth-modal" do
      click_button "Sign In"
    end
    expect(page).to have_content("Sign in to Jupiter")
  end

  def switch_to_registration_mode
    """Switch the modal from login to registration mode"""
    within "#auth-modal" do
      click_button "Sign up"
    end
    expect(page).to have_content("Create your Jupiter account")
  end

  # Form Interaction Helper Methods

  def fill_login_form(email:, password:, remember_me: false)
    """Fill the login form fields within the modal"""
    within "#auth-modal" do
      fill_in "email_address", with: email
      fill_in "password", with: password
      check "remember_me" if remember_me
    end
  end

  def fill_registration_form(first_name:, last_name:, email:, password:, password_confirmation: nil)
    """Fill the registration form fields within the modal"""
    password_confirmation ||= password

    within "#auth-modal" do
      fill_in "first_name", with: first_name
      fill_in "last_name", with: last_name
      fill_in "email_address", with: email
      fill_in "password", with: password
      fill_in "password_confirmation", with: password_confirmation
    end
  end

  def submit_login_form
    """Submit the login form"""
    within "#auth-modal" do
      find('input[type="submit"]').click
    end
  end

  def submit_registration_form
    """Submit the registration form"""
    within "#auth-modal" do
      find('input[type="submit"]').click
    end
  end

  # Expectation Helper Methods

  def expect_to_be_signed_in
    """Verify user is signed in by checking for sign out button"""
    expect(page).to have_button("Sign out")
    expect(page).not_to have_button("Sign In")
  end

  def expect_to_be_signed_out
    """Verify user is signed out by checking for sign in buttons"""
    expect(page).to have_button("Sign In")
    expect(page).to have_button("Create Account")
    expect(page).not_to have_button("Sign out")
  end

  def expect_modal_open
    """Verify the authentication modal is visible"""
    expect(page).to have_css("#auth-modal", visible: true, wait: 5)
  end

  def expect_modal_closed
    """Verify the authentication modal is hidden"""
    expect(page).not_to have_css("#auth-modal", visible: true)
  end

  def expect_login_mode
    """Verify modal is in login mode"""
    expect(page).to have_content("Sign in to Jupiter")
    expect(page).to have_button("Sign In")
    within "#auth-modal" do
      expect(page).to have_field("remember_me", visible: true)
      expect(page).not_to have_field("first_name", visible: true)
      expect(page).not_to have_field("password_confirmation", visible: true)
    end
  end

  def expect_registration_mode
    """Verify modal is in registration mode"""
    expect(page).to have_content("Create your Jupiter account")
    expect(page).to have_button("Create Account")
    within "#auth-modal" do
      expect(page).to have_field("first_name", visible: true)
      expect(page).to have_field("last_name", visible: true)
      expect(page).to have_field("password_confirmation", visible: true)
      expect(page).not_to have_field("remember_me", visible: true)
    end
  end

  def expect_form_action(expected_path)
    """Verify the form action points to the expected path"""
    form_action = page.find("#auth-modal form")['action']
    expect(form_action).to end_with(expected_path)
  end

  def expect_login_form_action
    """Verify form action is set for login (/session)"""
    expect_form_action("/session")
  end

  def expect_registration_form_action
    """Verify form action is set for registration (/users)"""
    expect_form_action("/users")
  end

  # Database Verification Helper Methods

  def expect_session_created(user:)
    """Verify a session was created for the user"""
    session = Session.find_by(user: user)
    expect(session).to be_present
    expect(session.ip_address).to be_present
    expect(session.user_agent).to be_present
    session
  end

  def expect_user_created(email:)
    """Verify a user was created with the given email"""
    user = User.find_by(email_address: email)
    expect(user).to be_present
    user
  end

  def expect_session_destroyed(session_id:)
    """Verify a session was destroyed"""
    expect(Session.find_by(id: session_id)).to be_nil
  end

  # Edge Case Helper Methods

  def handle_modal_already_open
    """Handle case where modal might already be open from previous test"""
    if page.has_css?("#auth-modal", visible: true)
      close_modal
    end
  end

  def handle_user_already_signed_in
    """Handle case where user might already be signed in"""
    if page.has_button?("Sign out")
      sign_out_user
    end
  end

  def reset_authentication_state
    """Reset authentication state for clean test slate"""
    handle_user_already_signed_in
    handle_modal_already_open
    visit root_path
  end

  # Feature Flag Helper Methods (for future use)

  def with_feature_flag(flag_name, enabled: true)
    """Temporarily enable/disable a feature flag for a test block"""
    # This will be implemented when feature flag tests are added
    # For now, it's a placeholder for the planned functionality
    yield
  end

  def expect_nationbuilder_button_visible
    """Verify NationBuilder OAuth button is visible (when feature flag enabled)"""
    within "#auth-modal" do
      expect(page).to have_link(href: "/auth/nationbuilder")
    end
  end

  def expect_nationbuilder_button_hidden
    """Verify NationBuilder OAuth button is hidden (when feature flag disabled)"""
    within "#auth-modal" do
      expect(page).not_to have_link(href: "/auth/nationbuilder")
    end
  end
end

# Include the helper module in system tests
RSpec.configure do |config|
  config.include SystemTestHelpers, type: :system
end

require 'rails_helper'

RSpec.describe "Authentication Sign-Up Page", type: :system do
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ])
  end

  describe "sign-up page accessibility and functionality" do
    it "displays proper page structure and accessibility features" do
      visit sign_up_path

      # Check page title and heading
      expect(page).to have_title('Jupiter')
      expect(page).to have_content('Create your account')

      # Check form accessibility
      expect(page).to have_field('First name', id: 'signup_first_name')
      expect(page).to have_field('Last name', id: 'signup_last_name')
      expect(page).to have_field('Email address', id: 'signup_email_address')
      expect(page).to have_field('Password', id: 'signup_password')
      expect(page).to have_field('Confirm password', id: 'signup_password_confirmation')

      # Check ARIA attributes
      email_field = find('#signup_email_address')
      expect(email_field['aria-label']).to eq('Email address')
      expect(email_field['aria-describedby']).to eq('email-help')

      password_field = find('#signup_password')
      expect(password_field['aria-label']).to eq('Password')
      expect(password_field['aria-describedby']).to eq('password-help')

      # Check helper text
      expect(page).to have_content("We'll use this to send you important updates")
      expect(page).to have_content('Must be at least 8 characters long')
      expect(page).to have_content('Re-enter your password to confirm')

      # Check links
      expect(page).to have_link('sign in to your existing account', href: sign_in_path)
      expect(page).to have_link('Terms of Service')
      expect(page).to have_link('Privacy Policy')

      # Check submit button
      expect(page).to have_button('Create Account')
    end

    it "successfully creates account with valid information" do
      visit sign_up_path

      fill_in 'First name', with: 'John'
      fill_in 'Last name', with: 'Doe'
      fill_in 'Email address', with: 'john.doe@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'password123'
      within('.max-w-md') { click_button 'Create Account' }

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('Account created!')
      expect(page).to have_content('verify your account')
    end

    it "displays validation errors for invalid data" do
      visit sign_up_path

      # Try to submit with mismatched passwords
      fill_in 'First name', with: 'John'
      fill_in 'Last name', with: 'Doe'
      fill_in 'Email address', with: 'john.doe@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'different'
      within('.max-w-md') { click_button 'Create Account' }

      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content("Password confirmation doesn't match")

      # Check that form data is preserved (except passwords)
      expect(find('#signup_first_name').value).to eq('John')
      expect(find('#signup_last_name').value).to eq('Doe')
      expect(find('#signup_email_address').value).to eq('john.doe@example.com')
      expect(find('#signup_password').value).to be_empty
      expect(find('#signup_password_confirmation').value).to be_empty
    end

    it "handles duplicate email with helpful message" do
      # Create existing user
      create(:user, email_address: 'existing@example.com', password: 'password123')

      visit sign_up_path

      fill_in 'First name', with: 'Jane'
      fill_in 'Last name', with: 'Smith'
      fill_in 'Email address', with: 'existing@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'password123'
      within('.max-w-md') { click_button 'Create Account' }

      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content('Email address has already been taken')
      expect(page).to have_link('Sign in instead', href: sign_in_path)
    end

    it "validates password length" do
      visit sign_up_path

      fill_in 'Email address', with: 'test@example.com'
      fill_in 'Password', with: '123'
      fill_in 'Confirm password', with: '123'
      within('.max-w-md') { click_button 'Create Account' }

      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content('Password is too short')
    end

    it "handles empty required fields" do
      visit sign_up_path

      # Use JavaScript to submit form bypassing HTML5 validation
      page.execute_script("document.querySelector('form').submit()")

      expect(page.current_path).to eq(sign_up_path)
      expect(page).to have_content("Email address can't be blank")
    end

    it "redirects authenticated users away from sign-up page" do
      user = create(:user, password: 'password123')

      # Sign in first
      visit sign_in_path
      fill_in 'Email address', with: user.email_address
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      expect(page).to have_current_path(root_path)

      # Try to visit sign-up page
      visit sign_up_path
      expect(page).to have_current_path(root_path)
    end

    it "allows registration without first/last name" do
      visit sign_up_path

      # Leave name fields empty
      fill_in 'Email address', with: 'minimal@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'password123'
      within('.max-w-md') { click_button 'Create Account' }

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('Account created!')
    end

    context "when NationBuilder OAuth is enabled" do
      before do
        allow(FeatureFlagService).to receive(:enabled?).with('nationbuilder_signin', anything).and_return(true)
      end

      it "displays NationBuilder OAuth button" do
        visit sign_up_path

        expect(page).to have_link('Sign Up with NationBuilder', href: '/auth/nationbuilder')
        expect(page).to have_content('Or continue with')
      end
    end

    context "when NationBuilder OAuth is disabled" do
      before do
        allow(FeatureFlagService).to receive(:enabled?).with('nationbuilder_signin', anything).and_return(false)
      end

      it "hides NationBuilder OAuth button" do
        visit sign_up_path

        expect(page).not_to have_link('Sign Up with NationBuilder')
        expect(page).not_to have_content('Or continue with')
      end
    end
  end

  describe "form validation and user experience" do
    it "provides real-time feedback for form fields" do
      visit sign_up_path

      # Check that required fields have proper attributes
      email_field = find('#signup_email_address')
      password_field = find('#signup_password')
      confirm_field = find('#signup_password_confirmation')

      expect(email_field['required']).to eq('true')
      expect(password_field['required']).to eq('true')
      expect(password_field['minlength']).to eq('8')
      expect(confirm_field['required']).to eq('true')
    end

    it "handles email normalization correctly" do
      visit sign_up_path

      fill_in 'Email address', with: '  UPPERCASE@EXAMPLE.COM  '
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'password123'
      within('.max-w-md') { click_button 'Create Account' }

      expect(page).to have_current_path(root_path)

      # Verify user was created with normalized email
      user = User.last
      expect(user.email_address).to eq('uppercase@example.com')
    end

    it "sends verification email on successful registration" do
      visit sign_up_path

      fill_in 'Email address', with: 'verify@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'password123'

      expect {
        within('.max-w-md') { click_button 'Create Account' }
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(page).to have_content('check your email to verify')
    end

    it "displays loading state on form submission" do
      visit sign_up_path

      fill_in 'Email address', with: 'loading@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Confirm password', with: 'password123'

      # Check that submit button has loading attributes
      submit_button = find('#signup_submit')
      expect(submit_button['data-disable-with']).to eq('Creating account...')
    end
  end

  describe "responsive design" do
    it "displays correctly on mobile" do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone SE size

      visit sign_up_path

      expect(page).to have_content('Create your account')
      expect(page).to have_field('Email address')
      expect(page).to have_field('Password')
      expect(page).to have_button('Create Account')

      # Check that name fields are in grid layout
      expect(page).to have_field('First name')
      expect(page).to have_field('Last name')
    end

    it "displays correctly on desktop" do
      page.driver.browser.manage.window.resize_to(1920, 1080)

      visit sign_up_path

      expect(page).to have_content('Create your account')
      expect(page).to have_field('Email address')
      expect(page).to have_field('Password')
      expect(page).to have_button('Create Account')
    end
  end

  describe "navigation between authentication pages" do
    it "allows easy navigation to sign-in page" do
      visit sign_up_path

      click_link 'sign in to your existing account'
      expect(page).to have_current_path(sign_in_path)
      expect(page).to have_content('Sign in to your account')
    end

    it "allows navigation from sign-in to sign-up" do
      visit sign_in_path

      click_link 'create a new account'
      expect(page).to have_current_path(sign_up_path)
      expect(page).to have_content('Create your account')
    end
  end
end

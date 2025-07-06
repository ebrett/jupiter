require 'rails_helper'

RSpec.describe "Authentication Sign-In Page", type: :system do
  let!(:user) { create(:user, password: 'password123') }

  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ])
  end

  describe "sign-in page accessibility and functionality" do
    it "displays proper page structure and accessibility features" do
      visit sign_in_path

      # Check page title and heading
      expect(page).to have_title('Jupiter')
      expect(page).to have_content('Sign in to your account')

      # Check form accessibility
      expect(page).to have_field('Email address', id: 'signin_email_address')
      expect(page).to have_field('Password', id: 'signin_password')
      expect(page).to have_field('Remember me', id: 'signin_remember_me')

      # Check ARIA attributes
      email_field = find('#signin_email_address')
      expect(email_field['aria-label']).to eq('Email address')
      expect(email_field['aria-describedby']).to eq('email-help')

      password_field = find('#signin_password')
      expect(password_field['aria-label']).to eq('Password')
      expect(password_field['aria-describedby']).to eq('password-help')

      # Check helper text
      expect(page).to have_content("We'll use this to sign you in and send important updates")
      expect(page).to have_content('Must be at least 8 characters long')

      # Check links
      expect(page).to have_link('create a new account', href: sign_up_path)
      expect(page).to have_link('Forgot your password?', href: new_password_path)

      # Check submit button
      expect(page).to have_button('Sign in')
    end

    it "successfully signs in with valid credentials" do
      visit sign_in_path

      fill_in 'Email address', with: user.email_address
      fill_in 'Password', with: 'password123'
      check 'Remember me'
      click_button 'Sign in'

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('Dashboard') # Assuming dashboard content
    end

    it "displays error for invalid credentials" do
      visit sign_in_path

      fill_in 'Email address', with: user.email_address
      fill_in 'Password', with: 'wrongpassword'
      click_button 'Sign in'

      expect(page.current_path).to eq(sign_in_path)
      expect(page).to have_content('Try another email address or password')

      # Check that email is preserved but password is not
      expect(find('#signin_email_address').value).to eq(user.email_address)
      expect(find('#signin_password').value).to be_empty
    end

    it "displays error for empty fields" do
      visit sign_in_path

      # Use JavaScript to submit form bypassing HTML5 validation
      page.execute_script("document.querySelector('form').submit()")

      expect(page.current_path).to eq(sign_in_path)
      expect(page).to have_content('Try another email address or password')
    end

    it "redirects authenticated users away from sign-in page" do
      # Sign in first
      visit sign_in_path
      fill_in 'Email address', with: user.email_address
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      expect(page).to have_current_path(root_path)

      # Try to visit sign-in page again
      visit sign_in_path
      expect(page).to have_current_path(root_path)
    end

    it "preserves return URL after authentication" do
      # Give user admin permissions to access users page
      admin_user = create(:user, :system_administrator, password: 'password123')

      # Try to access protected page
      visit users_path
      expect(page.current_path).to eq(sign_in_path)

      # Sign in
      fill_in 'Email address', with: admin_user.email_address
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      # Should redirect back to originally requested page
      expect(page).to have_current_path(users_path)
    end

    context "when NationBuilder OAuth is enabled" do
      before do
        allow(FeatureFlagService).to receive(:enabled?).with('nationbuilder_signin', anything).and_return(true)
      end

      it "displays NationBuilder OAuth button" do
        visit sign_in_path

        expect(page).to have_link('NationBuilder', href: '/auth/nationbuilder')
        expect(page).to have_content('Or continue with')
      end
    end

    context "when NationBuilder OAuth is disabled" do
      before do
        allow(FeatureFlagService).to receive(:enabled?).with('nationbuilder_signin', anything).and_return(false)
      end

      it "hides NationBuilder OAuth button" do
        visit sign_in_path

        expect(page).not_to have_link('NationBuilder')
        expect(page).not_to have_content('Or continue with')
      end
    end
  end

  describe "responsive design" do
    it "displays correctly on mobile" do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone SE size

      visit sign_in_path

      expect(page).to have_content('Sign in to your account')
      expect(page).to have_field('Email address')
      expect(page).to have_field('Password')
      expect(page).to have_button('Sign in')
    end

    it "displays correctly on desktop" do
      page.driver.browser.manage.window.resize_to(1920, 1080)

      visit sign_in_path

      expect(page).to have_content('Sign in to your account')
      expect(page).to have_field('Email address')
      expect(page).to have_field('Password')
      expect(page).to have_button('Sign in')
    end
  end
end

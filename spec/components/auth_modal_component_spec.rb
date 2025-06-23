require "rails_helper"

RSpec.describe AuthModalComponent, type: :component do
  describe "login mode" do
    context "when nationbuilder_signin feature flag is disabled" do
      it "renders login form title without oauth link" do
        render_inline(described_class.new(mode: :login))

        expect(rendered_content).to include("Sign in to Jupiter")
        expect(rendered_content).not_to include('href="/auth/nationbuilder"')
        expect(rendered_content).not_to include("Sign in with")
      end
    end

    context "when nationbuilder_signin feature flag is enabled" do
      before do
        FeatureFlag.find_or_create_by!(name: 'nationbuilder_signin') do |f|
          f.description = 'Test flag'
          f.enabled = true
        end
      end

      it "renders login form title and oauth link" do
        render_inline(described_class.new(mode: :login))

        expect(rendered_content).to include("Sign in to Jupiter")
        expect(rendered_content).to include('href="/auth/nationbuilder"')
        expect(rendered_content).to include("Sign in with") # Dynamic nation name
      end
    end

    it "renders login form input fields" do
      render_inline(described_class.new(mode: :login))

      expect(rendered_content).to include('name="email_address"')
      expect(rendered_content).to include('type="email"')
      expect(rendered_content).to include('name="password"')
      expect(rendered_content).to include('type="password"')
      expect(rendered_content).to include('name="remember_me"')
      expect(rendered_content).to include('type="checkbox"')
    end

    it "renders login form actions and links" do
      render_inline(described_class.new(mode: :login))

      expect(rendered_content).to include("Forgot password?")
      expect(rendered_content).to include('value="Sign in"')
      expect(rendered_content).to include("Don&#39;t have an account?")
      expect(rendered_content).to include("Sign up")
    end

    it "hides registration-only fields" do
      render_inline(described_class.new(mode: :login))

      # Fields are present but hidden with display: none
      expect(rendered_content).to include('name="first_name"')
      expect(rendered_content).to include('name="last_name"')
      expect(rendered_content).to include('name="password_confirmation"')
      expect(rendered_content).to include("Terms of Service")

      # Check they have the correct data attribute and are hidden
      expect(rendered_content).to include('data-auth-field="register" style="display: none;"')
    end

    it "sets form action to session path" do
      render_inline(described_class.new(mode: :login))

      expect(rendered_content).to include('action="/session"')
    end
  end

  describe "register mode" do
    context "when nationbuilder_signin feature flag is disabled" do
      it "renders registration form title without oauth link" do
        render_inline(described_class.new(mode: :register))

        expect(rendered_content).to include("Create your Jupiter account")
        expect(rendered_content).not_to include('href="/auth/nationbuilder"')
        expect(rendered_content).not_to include("Sign up with")
      end
    end

    context "when nationbuilder_signin feature flag is enabled" do
      before do
        flag = FeatureFlag.find_or_create_by!(name: 'nationbuilder_signin') do |f|
          f.description = 'Test flag'
          f.enabled = true
        end
      end

      it "renders registration form title and oauth link" do
        render_inline(described_class.new(mode: :register))

        expect(rendered_content).to include("Create your Jupiter account")
        expect(rendered_content).to include('href="/auth/nationbuilder"')
        expect(rendered_content).to include("Sign up with") # Dynamic nation name
      end
    end

    it "renders registration form input fields" do
      render_inline(described_class.new(mode: :register))

      expect(rendered_content).to include('name="first_name"')
      expect(rendered_content).to include('name="last_name"')
      expect(rendered_content).to include('name="email_address"')
      expect(rendered_content).to include('type="email"')
      expect(rendered_content).to include('name="password"')
      expect(rendered_content).to include('type="password"')
      expect(rendered_content).to include('name="password_confirmation"')
    end

    it "renders registration form actions and links" do
      render_inline(described_class.new(mode: :register))

      expect(rendered_content).to include('value="Create account"')
      expect(rendered_content).to include("Already have an account?")
      expect(rendered_content).to include("Sign in")
      expect(rendered_content).to include("Terms of Service")
    end

    it "hides login-only fields" do
      render_inline(described_class.new(mode: :register))

      # Fields are present but hidden with display: none
      expect(rendered_content).to include('name="remember_me"')
      expect(rendered_content).to include("Forgot password?")

      # Check they have the correct data attribute and are hidden
      expect(rendered_content).to include('data-auth-field="login" style="display: none;"')
    end

    it "sets form action to users path" do
      render_inline(described_class.new(mode: :register))

      expect(rendered_content).to include('action="/users"')
    end
  end

  describe "data attributes" do
    it "includes correct data controller and target attributes" do
      render_inline(described_class.new(mode: :login))

      expect(rendered_content).to include('data-controller="auth"')
      expect(rendered_content).to include('data-auth-mode-value="login"')
      expect(rendered_content).to include('data-auth-target="form"')
    end

    it "sets correct mode value for register" do
      render_inline(described_class.new(mode: :register))

      expect(rendered_content).to include('data-auth-mode-value="register"')
    end
  end

  describe "form action verification" do
    it "uses correct form action for login mode" do
      render_inline(described_class.new(mode: :login))

      # Verify form action points to session endpoint
      expect(rendered_content).to include('action="/session"')
      expect(rendered_content).not_to include('action="/users"')
    end

    it "uses correct form action for registration mode" do
      render_inline(described_class.new(mode: :register))

      # Verify form action points to users endpoint
      expect(rendered_content).to include('action="/users"')
      expect(rendered_content).not_to include('action="/session"')
    end

    it "form method is POST for both modes" do
      # Test login mode
      render_inline(described_class.new(mode: :login))
      expect(rendered_content).to include('method="post"')

      # Test registration mode
      render_inline(described_class.new(mode: :register))
      expect(rendered_content).to include('method="post"')
    end

    it "addresses the original PRD bug about signup redirecting to sign-in" do
      # This test specifically verifies the bug mentioned in the PRD:
      # "Recent issues include the signup form redirecting to sign-in instead of creating accounts
      # due to incorrect form action paths"

      render_inline(described_class.new(mode: :register))

      # The critical test: registration form must POST to /users, not /session
      expect(rendered_content).to include('action="/users"'),
        "Registration form should POST to /users, not /session. This was the original bug."
      expect(rendered_content).not_to include('action="/session"'),
        "Registration form must NOT POST to /session as that would cause the reported bug."
    end
  end

  describe "stimulus controller data attributes" do
    it "includes required data attributes for JavaScript functionality" do
      render_inline(described_class.new(mode: :login))

      # Verify Stimulus controller attributes
      expect(rendered_content).to include('data-controller="auth"')
      expect(rendered_content).to include('data-auth-target="form"')
      expect(rendered_content).to include('data-auth-mode-value="login"')

      # Verify action data attributes for mode switching
      expect(rendered_content).to include('data-action="click->auth#switchToRegister"')
    end

    it "includes correct action data attributes for registration mode" do
      render_inline(described_class.new(mode: :register))

      expect(rendered_content).to include('data-controller="auth"')
      expect(rendered_content).to include('data-auth-mode-value="register"')
      expect(rendered_content).to include('data-action="click->auth#switchToLogin"')
    end

    it "includes data attributes for field visibility control" do
      render_inline(described_class.new(mode: :login))

      # Verify fields have correct data attributes for show/hide behavior
      expect(rendered_content).to include('data-auth-field="register"')
      expect(rendered_content).to include('data-auth-field="login"')
    end
  end

  describe "submit button text verification" do
    it "displays 'Sign in' for login mode" do
      render_inline(described_class.new(mode: :login))

      expect(rendered_content).to include('value="Sign in"')
      expect(rendered_content).not_to include('value="Create account"')
    end

    it "displays 'Create account' for registration mode" do
      render_inline(described_class.new(mode: :register))

      expect(rendered_content).to include('value="Create account"')
      expect(rendered_content).not_to include('value="Sign in"')
    end

    it "submit button has correct type and styling for both modes" do
      # Test login mode
      render_inline(described_class.new(mode: :login))
      expect(rendered_content).to include('type="submit"')
      expect(rendered_content).to include('class="w-full flex justify-center py-3 px-4')

      # Test registration mode
      render_inline(described_class.new(mode: :register))
      expect(rendered_content).to include('type="submit"')
      expect(rendered_content).to include('class="w-full flex justify-center py-3 px-4')
    end
  end

  describe "field visibility by mode" do
    it "shows only login-specific fields in login mode" do
      render_inline(described_class.new(mode: :login))

      # Login-specific fields should be visible
      expect(rendered_content).to include('name="remember_me"')
      expect(rendered_content).to include('data-auth-field="login"')
      expect(rendered_content).not_to include('data-auth-field="login" style="display: none;"')

      # Registration-specific fields should be hidden
      expect(rendered_content).to include('data-auth-field="register" style="display: none;"')
      expect(rendered_content).to include('name="first_name"')
      expect(rendered_content).to include('name="last_name"')
      expect(rendered_content).to include('name="password_confirmation"')
    end

    it "shows only registration-specific fields in registration mode" do
      render_inline(described_class.new(mode: :register))

      # Registration-specific fields should be visible
      expect(rendered_content).to include('name="first_name"')
      expect(rendered_content).to include('name="last_name"')
      expect(rendered_content).to include('name="password_confirmation"')
      expect(rendered_content).to include('data-auth-field="register"')
      expect(rendered_content).not_to include('data-auth-field="register" style="display: none;"')

      # Login-specific fields should be hidden
      expect(rendered_content).to include('data-auth-field="login" style="display: none;"')
      expect(rendered_content).to include('name="remember_me"')
    end

    it "password confirmation field is only required in registration mode" do
      # Login mode - password confirmation not required
      render_inline(described_class.new(mode: :login))
      expect(rendered_content).to include('name="password_confirmation"')
      # In login mode, password confirmation field exists but is not required (hidden field)
      expect(rendered_content).not_to match(/required="required"[^>]*name="password_confirmation"/)

      # Registration mode - password confirmation is required
      render_inline(described_class.new(mode: :register))
      expect(rendered_content).to match(/required="required"[^>]*name="password_confirmation"/)
    end

    it "name fields are only required in registration mode" do
      # Login mode - name fields not required
      render_inline(described_class.new(mode: :login))
      expect(rendered_content).not_to match(/required="required"[^>]*name="first_name"/)
      expect(rendered_content).not_to match(/required="required"[^>]*name="last_name"/)

      # Registration mode - name fields are required
      render_inline(described_class.new(mode: :register))
      expect(rendered_content).to match(/required="required"[^>]*name="first_name"/)
      expect(rendered_content).to match(/required="required"[^>]*name="last_name"/)
    end
  end

  describe "form structure verification" do
    it "renders correct form structure for login mode" do
      render_inline(described_class.new(mode: :login))

      # Verify form wrapper
      expect(rendered_content).to include('<form')
      expect(rendered_content).to include('action="/session"')
      expect(rendered_content).to include('method="post"')
      expect(rendered_content).to include('data-auth-target="form"')

      # Verify essential fields present
      expect(rendered_content).to include('name="email_address"')
      expect(rendered_content).to include('name="password"')
      expect(rendered_content).to include('type="submit"')

      # Verify form submission works with proper structure
      expect(rendered_content).to include('</form>')
    end

    it "renders correct form structure for registration mode" do
      render_inline(described_class.new(mode: :register))

      # Verify form wrapper
      expect(rendered_content).to include('<form')
      expect(rendered_content).to include('action="/users"')
      expect(rendered_content).to include('method="post"')
      expect(rendered_content).to include('data-auth-target="form"')

      # Verify all registration fields present
      expect(rendered_content).to include('name="first_name"')
      expect(rendered_content).to include('name="last_name"')
      expect(rendered_content).to include('name="email_address"')
      expect(rendered_content).to include('name="password"')
      expect(rendered_content).to include('name="password_confirmation"')
      expect(rendered_content).to include('type="submit"')

      # Verify form submission works with proper structure
      expect(rendered_content).to include('</form>')
    end
  end

  describe "required HTML attributes" do
    it "includes all required HTML attributes for accessibility and functionality" do
      render_inline(described_class.new(mode: :login))

      # Form attributes
      expect(rendered_content).to include('action="/session"')
      expect(rendered_content).to include('method="post"')

      # Input field attributes
      expect(rendered_content).to include('type="email"')
      expect(rendered_content).to include('type="password"')
      expect(rendered_content).to include('type="checkbox"')
      expect(rendered_content).to include('type="submit"')

      # Required field attributes
      expect(rendered_content).to include('required')

      # Stimulus data attributes
      expect(rendered_content).to include('data-controller="auth"')
      expect(rendered_content).to include('data-auth-target="form"')
      expect(rendered_content).to include('data-auth-mode-value="login"')

      # Field visibility attributes
      expect(rendered_content).to include('data-auth-field="login"')
      expect(rendered_content).to include('data-auth-field="register"')
    end

    it "includes proper labels and accessibility attributes" do
      render_inline(described_class.new(mode: :login))

      # Labels for form fields
      expect(rendered_content).to include('<label')
      expect(rendered_content).to include('Email address')
      expect(rendered_content).to include('Password')
      expect(rendered_content).to include('Remember me')

      # CSS classes for styling
      expect(rendered_content).to include('class="')
      expect(rendered_content).to include('w-full')
    end
  end
end

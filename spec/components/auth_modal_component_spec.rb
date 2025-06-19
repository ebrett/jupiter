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
end

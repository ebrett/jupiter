require 'rails_helper'

RSpec.describe "Users (Sign-Up)", type: :request do
  describe "GET /sign-up" do
    it "returns successful response" do
      get sign_up_path
      expect(response).to have_http_status(:success)
    end

    it "renders sign-up form with required elements" do
      get sign_up_path
      expect(response.body).to include('type="email"')
      expect(response.body).to include('type="password"')
      expect(response.body).to include('first_name')
      expect(response.body).to include('last_name')
      expect(response.body).to include('password_confirmation')
      expect(response.body).to include('Create Account')
    end

    it "includes proper ARIA labels and accessibility attributes" do
      get sign_up_path
      expect(response.body).to include('aria-label')
      expect(response.body).to include('for="')
    end

    it "includes link to sign-in page" do
      get sign_up_path
      expect(response.body).to include('sign in')
      expect(response.body).to include(sign_in_path)
    end

    it "includes terms of service and privacy policy links" do
      get sign_up_path
      expect(response.body).to include('Terms of Service')
      expect(response.body).to include('Privacy Policy')
    end

    it "includes NationBuilder OAuth button when feature enabled" do
      allow(FeatureFlagService).to receive(:enabled?).with('nationbuilder_signin', nil).and_return(true)

      get sign_up_path
      expect(response.body).to include('Sign Up with')
      expect(response.body).to include('/auth/nationbuilder')
    end

    it "hides NationBuilder OAuth button when feature disabled" do
      allow(FeatureFlagService).to receive(:enabled?).with('nationbuilder_signin', nil).and_return(false)

      get sign_up_path
      expect(response.body).not_to include('Sign Up with')
    end

    it "redirects authenticated users to root" do
      user = create(:user)
      sign_in_as(user)

      get sign_up_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /users (registration)" do
    let(:valid_params) do
      {
        first_name: 'John',
        last_name: 'Doe',
        email_address: 'john.doe@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    context "with valid registration data" do
      it "creates a new user" do
        expect {
          post users_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "creates user with correct attributes" do
        post users_path, params: valid_params

        user = User.last
        expect(user.first_name).to eq('John')
        expect(user.last_name).to eq('Doe')
        expect(user.email_address).to eq('john.doe@example.com')
        expect(user.password_digest).to be_present
      end

      it "sends verification email for email/password users" do
        expect {
          post users_path, params: valid_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end

      it "redirects to root with success message" do
        post users_path, params: valid_params

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('Account created!')
        expect(flash[:notice]).to include('verify your account')
      end

      it "does not automatically sign in email/password users" do
        post users_path, params: valid_params

        expect(response.cookies['session_id']).to be_nil
      end

      it "handles redirect parameters for post-registration flow" do
        post users_path, params: valid_params.merge(redirect_to: '/dashboard')

        # Should still redirect to root for verification, but could be enhanced later
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid registration data" do
      it "handles missing email address" do
        post users_path, params: valid_params.except(:email_address)

        expect(response).to redirect_to(sign_up_path(first_name: 'John', last_name: 'Doe'))
        expect(flash[:alert]).to include('Email address can\'t be blank')
      end

      it "handles missing password" do
        post users_path, params: valid_params.except(:password)

        expect(response).to redirect_to(sign_up_path(
          first_name: 'John',
          last_name: 'Doe',
          email_address: 'john.doe@example.com'
        ))
        expect(flash[:alert]).to include('Password can\'t be blank')
      end

      it "handles password too short" do
        post users_path, params: valid_params.merge(password: '123', password_confirmation: '123')

        expect(response).to redirect_to(sign_up_path(
          first_name: 'John',
          last_name: 'Doe',
          email_address: 'john.doe@example.com'
        ))
        expect(flash[:alert]).to include('Password is too short')
      end

      it "handles password confirmation mismatch" do
        post users_path, params: valid_params.merge(password_confirmation: 'different')

        expect(response).to redirect_to(sign_up_path(
          first_name: 'John',
          last_name: 'Doe',
          email_address: 'john.doe@example.com'
        ))
        expect(flash[:alert]).to include('Password confirmation doesn\'t match')
      end

      it "handles duplicate email address" do
        create(:user, email_address: 'john.doe@example.com')

        post users_path, params: valid_params

        expect(response).to redirect_to(sign_up_path(
          first_name: 'John',
          last_name: 'Doe',
          email_address: 'john.doe@example.com'
        ))
        expect(flash[:alert]).to include('Email address has already been taken')
      end

      it "provides helpful message for existing email with sign-in link" do
        create(:user, email_address: 'john.doe@example.com')

        post users_path, params: valid_params

        expect(response).to redirect_to(sign_up_path(
          first_name: 'John',
          last_name: 'Doe',
          email_address: 'john.doe@example.com'
        ))
        expect(flash[:alert]).to include('Email address has already been taken')
      end

      it "does not create user record on validation failure" do
        expect {
          post users_path, params: valid_params.except(:email_address)
        }.not_to change(User, :count)
      end

      it "does not send verification email on validation failure" do
        expect {
          post users_path, params: valid_params.except(:email_address)
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "form data persistence on validation failure" do
      it "preserves form data except password fields" do
        post users_path, params: valid_params.merge(password_confirmation: 'different')

        follow_redirect!
        expect(response.body).to include('John') # first_name
        expect(response.body).to include('Doe') # last_name
        expect(response.body).to include('john.doe@example.com') # email
        expect(response.body).not_to include('password123') # password should not persist
      end
    end

    context "edge cases" do
      it "handles missing first and last name gracefully" do
        post users_path, params: valid_params.except(:first_name, :last_name)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('Account created!')
      end

      it "normalizes email address to lowercase" do
        post users_path, params: valid_params.merge(email_address: 'JOHN.DOE@EXAMPLE.COM')

        user = User.last
        expect(user.email_address).to eq('john.doe@example.com')
      end

      it "strips whitespace from email address" do
        post users_path, params: valid_params.merge(email_address: '  john.doe@example.com  ')

        user = User.last
        expect(user.email_address).to eq('john.doe@example.com')
      end
    end
  end

  private

  def sign_in_as(user)
    # Helper method to simulate authentication
    post session_path, params: {
      email_address: user.email_address,
      password: 'password123'
    }
  end
end

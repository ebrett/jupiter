require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, password: 'password123') }

  describe "GET /sign-in" do
    it "returns successful response" do
      get sign_in_path
      expect(response).to have_http_status(:success)
    end

    it "renders sign-in form with required elements" do
      get sign_in_path
      expect(response.body).to include('type="email"')
      expect(response.body).to include('type="password"')
      expect(response.body).to include('type="checkbox"')
      expect(response.body).to include('Sign In')
    end

    it "includes proper ARIA labels and accessibility attributes" do
      get sign_in_path
      expect(response.body).to include('aria-label')
      expect(response.body).to include('for="')
    end

    it "includes forgot password link" do
      get sign_in_path
      expect(response.body).to include('Forgot your password')
    end

    it "includes link to sign-up page" do
      get sign_in_path
      expect(response.body).to include('create a new account')
      expect(response.body).to include(sign_up_path)
    end

    it "includes NationBuilder OAuth button when feature enabled" do
      allow(FeatureFlagService).to receive(:enabled?).with('nationbuilder_signin', nil).and_return(true)

      get sign_in_path
      expect(response.body).to include('NationBuilder')
      expect(response.body).to include('/auth/nationbuilder')
    end

    it "hides NationBuilder OAuth button when feature disabled" do
      allow(FeatureFlagService).to receive(:enabled?).with('nationbuilder_signin', nil).and_return(false)

      get sign_in_path
      expect(response.body).not_to include('Sign In with')
    end
  end

  describe "POST /sign-in (via session_path)" do
    context "with valid credentials" do
      it "signs in the user and redirects to root" do
        post session_path, params: {
          email_address: user.email_address,
          password: 'password123'
        }

        expect(response).to redirect_to(root_path)
        expect(response.cookies['session_id']).to be_present
      end

      it "creates a session record" do
        expect {
          post session_path, params: {
            email_address: user.email_address,
            password: 'password123'
          }
        }.to change(Session, :count).by(1)
      end

      it "handles remember me functionality" do
        post session_path, params: {
          email_address: user.email_address,
          password: 'password123',
          remember_me: '1'
        }

        expect(response).to redirect_to(root_path)
        session = Session.last
        expect(session.remember_me).to be true
      end

      it "redirects to stored return URL after authentication" do
        # Simulate storing a return URL
        get "/users"  # This should store the URL and redirect to sign-in
        expect(response).to redirect_to(sign_in_path)

        # Now sign in and expect redirect to stored URL
        post session_path, params: {
          email_address: user.email_address,
          password: 'password123'
        }

        expect(response).to redirect_to(users_path)
      end
    end

    context "with invalid credentials" do
      it "redirects back to sign-in with error for wrong password" do
        post session_path, params: {
          email_address: user.email_address,
          password: 'wrongpassword'
        }

        expect(response).to redirect_to(sign_in_path(email_address: user.email_address))
        expect(flash[:alert]).to include('Try another email address or password')
      end

      it "redirects back to sign-in with error for non-existent user" do
        post session_path, params: {
          email_address: 'nonexistent@example.com',
          password: 'password123'
        }

        expect(response).to redirect_to(sign_in_path(email_address: 'nonexistent@example.com'))
        expect(flash[:alert]).to include('Try another email address or password')
      end

      it "handles missing email address" do
        post session_path, params: {
          password: 'password123'
        }

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to include('Try another email address or password')
      end

      it "handles missing password" do
        post session_path, params: {
          email_address: user.email_address
        }

        expect(response).to redirect_to(sign_in_path(email_address: user.email_address))
        expect(flash[:alert]).to include('Try another email address or password')
      end

      it "does not create a session record" do
        expect {
          post session_path, params: {
            email_address: user.email_address,
            password: 'wrongpassword'
          }
        }.not_to change(Session, :count)
      end
    end

    context "form data persistence" do
      it "preserves email address on validation failure" do
        post session_path, params: {
          email_address: user.email_address,
          password: 'wrongpassword'
        }

        follow_redirect!
        expect(response.body).to include(user.email_address)
      end

      it "does not preserve password on validation failure" do
        post session_path, params: {
          email_address: user.email_address,
          password: 'wrongpassword'
        }

        follow_redirect!
        expect(response.body).not_to include('wrongpassword')
      end
    end
  end
end

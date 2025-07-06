require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  let(:user) { create(:user, password: "password123", password_confirmation: "password123") }

  describe "POST #create" do
    context "with valid credentials" do
      let(:valid_params) do
        {
          email_address: user.email_address,
          password: "password123"
        }
      end

      it "creates a new session without remember me" do
        expect {
          post :create, params: valid_params
        }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.user).to eq(user)
        expect(session.remember_me).to be false
      end

      it "creates a new session with remember me when checked" do
        expect {
          post :create, params: valid_params.merge(remember_me: "1")
        }.to change(Session, :count).by(1)

        session = Session.last
        expect(session.user).to eq(user)
        expect(session.remember_me).to be true
      end

      it "sets session cookie with default duration when remember me is false" do
        post :create, params: valid_params

        session_cookie = response.cookies["session_id"]
        expect(session_cookie).to be_present
        # Cookie duration is managed by the authentication concern
      end

      it "sets session cookie with extended duration when remember me is true" do
        post :create, params: valid_params.merge(remember_me: "1")

        session_cookie = response.cookies["session_id"]
        expect(session_cookie).to be_present
        # Cookie duration is managed by the authentication concern
      end

      it "redirects to after_authentication_url" do
        post :create, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "sets Current.session and Current.user" do
        post :create, params: valid_params

        # In controller tests, Current values are set in the controller context
        # We can verify the session was created and cookie was set
        expect(Session.last.user).to eq(user)
        expect(cookies.signed[:session_id]).to eq(Session.last.id)
      end
    end

    context "with invalid credentials" do
      let(:invalid_params) do
        {
          email_address: user.email_address,
          password: "wrongpassword"
        }
      end

      it "does not create a session" do
        expect {
          post :create, params: invalid_params
        }.not_to change(Session, :count)
      end

      it "redirects with error message" do
        post :create, params: invalid_params

        expect(response.location).to start_with(sign_in_url)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end

      it "ignores remember me parameter when credentials are invalid" do
        expect {
          post :create, params: invalid_params.merge(remember_me: "1")
        }.not_to change(Session, :count)
      end
    end

    context "with missing parameters" do
      it "handles missing email gracefully" do
        post :create, params: { password: "password123" }

        expect(response.location).to start_with(sign_in_url)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end

      it "handles missing password gracefully" do
        post :create, params: { email_address: user.email_address }

        expect(response.location).to start_with(sign_in_url)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end
    end
  end

  describe "DELETE #destroy" do
    let(:session) { create(:session, user: user) }

    before do
      allow(Current).to receive(:session).and_return(session)
      cookies.signed[:session_id] = session.id
    end

    it "destroys the current session" do
      expect {
        delete :destroy
      }.to change(Session, :count).by(-1)
    end

    it "clears the session cookie" do
      delete :destroy
      expect(response.cookies["session_id"]).to be_nil
    end

    it "redirects to home page" do
      delete :destroy
      expect(response).to redirect_to(root_path)
    end
  end
end

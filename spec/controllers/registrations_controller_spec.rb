require "rails_helper"

RSpec.describe RegistrationsController, type: :controller do
  describe "POST #create" do
    let(:valid_params) do
      {
        email_address: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123",
        first_name: "John",
        last_name: "Doe"
      }
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "creates an email/password user" do
        post :create, params: valid_params

        user = User.last
        expect(user.email_address).to eq("newuser@example.com")
        expect(user.first_name).to eq("John")
        expect(user.last_name).to eq("Doe")
        expect(user.email_password_user?).to be true
        expect(user.nationbuilder_user?).to be false
      end

      it "sends verification email" do
        expect {
          post :create, params: valid_params
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include("newuser@example.com")
        expect(email.subject).to match(/verify/i)
      end

      it "redirects with success message" do
        post :create, params: valid_params

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/Account created.*check your email/i)
      end

      it "does not auto-login the user" do
        post :create, params: valid_params

        expect(Current.user).to be_nil
      end
    end

    context "with invalid parameters" do
      it "does not create a user with missing email" do
        expect {
          post :create, params: valid_params.except(:email_address)
        }.not_to change(User, :count)
      end

      it "does not create a user with short password" do
        expect {
          post :create, params: valid_params.merge(password: "short")
        }.not_to change(User, :count)
      end

      it "does not create a user with mismatched password confirmation" do
        expect {
          post :create, params: valid_params.merge(password_confirmation: "different")
        }.not_to change(User, :count)
      end

      it "redirects with error message" do
        post :create, params: valid_params.merge(email_address: "")

        expect(response.location).to start_with(sign_up_url)
        expect(flash[:alert]).to be_present
      end

      it "does not send verification email" do
        expect {
          post :create, params: valid_params.merge(email_address: "")
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context "with duplicate email" do
      before do
        create(:user, email_address: "newuser@example.com")
      end

      it "does not create a duplicate user" do
        expect {
          post :create, params: valid_params
        }.not_to change(User, :count)
      end

      it "shows error message" do
        post :create, params: valid_params

        expect(response.location).to start_with(sign_up_url)
        expect(flash[:alert]).to include("Email address has already been taken")
      end
    end
  end
end

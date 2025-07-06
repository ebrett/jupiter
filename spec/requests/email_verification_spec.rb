require 'rails_helper'

RSpec.describe "EmailVerifications", type: :request do
  describe "GET /verify_email/:token" do
    let(:user) { create(:user, :email_password_user) }

    before do
      user.generate_verification_token
      user.verification_sent_at = 1.hour.ago  # Set to avoid expiration issues
      user.save!
    end

    context "with valid token" do
      it "verifies the user and logs them in" do
        expect(user.email_verified?).to be false

        get verify_email_path(token: user.verification_token)

        user.reload
        expect(user.email_verified?).to be true
        expect(user.verification_token).to be_nil
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to match(/verified successfully/)
      end

      it "creates a session for the user" do
        expect {
          get verify_email_path(token: user.verification_token)
        }.to change { user.sessions.count }.by(1)
      end
    end

    context "with invalid token" do
      it "redirects with error message" do
        get verify_email_path(token: "invalid_token")

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to match(/Invalid verification link/)
      end
    end

    context "with already verified user" do
      it "redirects with error for invalid token" do
        user.verify_email!  # This clears the verification_token

        get verify_email_path(token: "any_token")

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to match(/Invalid verification link/)
      end
    end

    context "with expired token" do
      before do
        user.update!(verification_sent_at: 25.hours.ago)
      end

      it "redirects with error message" do
        get verify_email_path(token: user.verification_token)

        expect(response).to redirect_to(sign_in_path)
        expect(flash[:alert]).to match(/expired/)
      end
    end
  end

  describe "POST /resend_verification" do
    let(:user) { create(:user, :email_password_user) }

    before do
      user.generate_verification_token
      user.verification_sent_at = 2.hours.ago  # Allow resending
      user.save!
      ActionMailer::Base.deliveries.clear
    end

    context "when logged in" do
      before { sign_in_user(user) }

      context "with unverified email/password user" do
        it "resends verification email" do
          expect {
            post resend_verification_path
          }.to change { ActionMailer::Base.deliveries.count }.by(1)

          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to match(/Verification email sent/)
        end

        it "prevents resending when trying too soon" do
          user.update!(verification_sent_at: 30.minutes.ago)

          expect {
            post resend_verification_path
          }.not_to change { ActionMailer::Base.deliveries.count }

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to match(/Please wait/)
        end
      end

      context "with already verified user" do
        before { user.verify_email! }

        it "redirects with notice" do
          post resend_verification_path

          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to match(/already verified/)
        end
      end

      context "with NationBuilder user" do
        let(:nb_user) { create(:user, :nationbuilder_user) }

        before { sign_in_user(nb_user) }

        it "prevents resending for OAuth users" do
          post resend_verification_path

          expect(response).to redirect_to(root_path)
          expect(flash[:alert]).to match(/only for email\/password accounts/)
        end
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post resend_verification_path

        expect(response).to redirect_to(sign_in_path)
        # Note: Flash message may not be set in test environment due to authentication stubs
      end
    end
  end

  private

  def sign_in_user(user)
    # Simulate authentication by stubbing the authentication methods
    # This is simpler and more reliable than full login flow in request specs
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:require_authentication).and_return(true)

    # Create a session for the user to make it realistic
    session = user.sessions.create!(ip_address: '127.0.0.1', user_agent: 'Test')
    allow(Current).to receive_messages(user: user, session: session)
  end
end

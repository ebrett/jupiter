require "rails_helper"

RSpec.describe EmailVerificationMailer, type: :mailer do
  describe "verify_email" do
    let(:user) { create(:user, :email_password_user, first_name: 'John') }
    let(:mail) { described_class.verify_email(user) }

    before do
      user.generate_verification_token
    end

    it "renders the headers" do
      expect(mail.subject).to eq("Verify your Jupiter account email address")
      expect(mail.to).to eq([ user.email_address ])
      expect(mail.from).to eq([ "noreply@jupiter.example.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Welcome to Jupiter!")
      expect(mail.body.encoded).to match("Hi John")
      expect(mail.body.encoded).to match("verify your email address")
    end

    it "includes verification URL" do
      expect(mail.body.encoded).to match(user.verification_token)
    end

    context "when user has no first name" do
      let(:user) { create(:user, :email_password_user, first_name: nil) }

      it "uses generic greeting" do
        expect(mail.body.encoded).to match("Hi there")
      end
    end
  end
end

require 'rails_helper'

RSpec.describe System::OauthStatusController, type: :controller do
  let(:system_administrator) { create(:user, :with_system_administrator_role) }
  let(:user_without_oauth) { create(:user, email_address: "no-oauth@example.com") }

  before do
    # Set up authentication
    session = system_administrator.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id

    # Create a user without OAuth connection
    user_without_oauth
  end

  describe "GET #index" do
    context "when users have no NationBuilder connection" do
      it "handles nil status values gracefully" do
        expect {
          get :index
        }.not_to raise_error

        expect(response).to have_http_status(:success)
      end

      it "does not crash when users have nil OAuth status" do
        get :index
        expect(response.status).not_to eq(500)
      end

      it "handles nil status in the view without NoMethodError" do
        # This specifically tests the fix for the NoMethodError: undefined method 'humanize' for nil
        expect {
          get :index
        }.not_to raise_error
      end
    end
  end
end

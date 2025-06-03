require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  let(:admin_user) { create(:user, :with_super_admin_role) }
  let(:user_without_oauth) { create(:user, email_address: "no-oauth@example.com") }

  before do
    # Set up authentication
    session = admin_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id

    # Create a user without OAuth connection
    user_without_oauth
  end

  describe "GET #oauth_status" do
    context "when users have no NationBuilder connection" do
      it "handles nil status values gracefully" do
        expect {
          get :oauth_status
        }.not_to raise_error

        expect(response).to have_http_status(:success)
      end

      it "does not crash when users have nil OAuth status" do
        get :oauth_status
        expect(response.status).not_to eq(500)
      end

      it "handles nil status in the view without NoMethodError" do
        # This specifically tests the fix for the NoMethodError: undefined method 'humanize' for nil
        expect {
          get :oauth_status
        }.not_to raise_error(NoMethodError)
      end
    end

    context "analyzing user_oauth_status data structure" do
      it "shows what data structure is returned for users without OAuth" do
        dashboard = NationbuilderAdminDashboard.new
        user_oauth_status = dashboard.user_oauth_status(limit: 100)

        puts "User OAuth Status data: #{user_oauth_status.inspect}"

        # Check if any users have nil status
        nil_status_users = user_oauth_status.select { |user| user[:status].nil? }
        puts "Users with nil status: #{nil_status_users.count}"

        expect(user_oauth_status).to be_an(Array)
      end
    end
  end
end

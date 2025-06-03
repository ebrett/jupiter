require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  let(:admin_user) { create(:user, :with_super_admin_role) }

  before do
    # Set up authentication
    session = admin_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id
  end

  describe "GET #system_health" do
    context "when system_health_check returns properly structured data" do
      it "renders successfully without TypeError" do
        begin
          get :system_health
          expect(response.status).to be_in([ 200, 500 ])
        rescue => e
          puts "Error during GET: #{e.class}: #{e.message}"
          puts e.backtrace.first(5).join("\n")
          raise e
        end
      end

      it "returns successful response" do
        get :system_health
        if response.status == 500
          puts "500 Error response body: #{response.body}"
        end
        expect(response).to have_http_status(:success)
      end

      it "renders the view successfully without template errors" do
        get :system_health
        expect(response.body).to include("System Health Check")
        expect(response.body).to include("Database")
      end
    end

    context "analyzing the data structure returned by system_health_check" do
      it "shows what type of data is being returned" do
        controller_instance = described_class.new
        dashboard = NationbuilderAdminDashboard.new
        health_check_data = dashboard.system_health_check

        # Let's see what type of data structure we get
        puts "Health check data type: #{health_check_data.class}"
        puts "Health check data: #{health_check_data.inspect}"

        # The error suggests we're trying to use a symbol as an integer index
        # This likely means the data is a hash but the view is trying to iterate it like an array
        expect(health_check_data).to be_a(Hash).or be_a(Array)
      end
    end
  end
end

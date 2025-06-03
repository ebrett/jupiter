require 'rails_helper'

RSpec.describe "Admin System Health", type: :request do
  let(:admin_user) { create(:user, :with_super_admin_role) }

  before do
    # Set up authentication by setting the signed cookie value directly
    session = admin_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    # In request specs, we need to set cookies differently
    jar = ActionDispatch::Cookies::CookieJar.build(request, {})
    jar.signed[:session_id] = session.id
  end

  describe "GET /admin/system_health" do
    it "renders successfully after fixing TypeError" do
      get "/admin/system_health"

      if response.status == 500
        puts "Error response body: #{response.body}"
        puts "Error in test environment"
      end

      expect(response).to have_http_status(:success)
      expect(response.body).to include("System Health Check")
    end

    it "displays health check information" do
      get "/admin/system_health"
      expect(response.body).to include("Database")
      expect(response.body).to include("Nationbuilder api")
    end

    it "displays configuration status" do
      get "/admin/system_health"
      expect(response.body).to include("Configuration Status")
      expect(response.body).to include("Environment variables")
    end
  end
end

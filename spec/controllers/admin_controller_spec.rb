require 'rails_helper'

RSpec.describe AdminController, type: :controller do
  let(:admin_user) { create(:user, :with_super_admin_role) }
  let(:regular_user) { create(:user) }

  before do
    # Set up authentication
    session = admin_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id
  end

  describe "GET #oauth_status" do
    context "when admin user is authenticated" do
      it "renders the oauth_status page successfully" do
        get :oauth_status
        expect(response).to have_http_status(:success)
      end

      it "does not raise template missing error" do
        expect { get :oauth_status }.not_to raise_error
      end
    end

    context "when accessing as JSON" do
      it "returns JSON response" do
        get :oauth_status, format: :json
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe "GET #system_health" do
    context "when admin user is authenticated" do
      it "renders the system_health page successfully" do
        get :system_health
        expect(response).to have_http_status(:success)
      end

      it "does not raise template missing error" do
        expect { get :system_health }.not_to raise_error
      end
    end

    context "when accessing as JSON" do
      it "returns JSON response" do
        get :system_health, format: :json
        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe "GET #index" do
    it "renders the index page successfully" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "does not raise template missing error" do
      expect { get :index }.not_to raise_error
    end
  end

  context "when regular user tries to access" do
    before do
      # Change to regular user session
      session = regular_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
      cookies.signed[:session_id] = session.id
    end

    it "allows access for now (no admin restriction implemented)" do
      get :oauth_status
      expect(response).to have_http_status(:success)
    end
  end
end

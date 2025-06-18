require 'rails_helper'

RSpec.describe System::HealthController, type: :controller do
  let(:system_administrator) { create(:user, :with_system_administrator_role) }

  before do
    # Set up authentication
    session = system_administrator.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id
  end

  describe "GET #index" do
    it "returns successful response" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "assigns health check data" do
      get :index
      expect(assigns(:health_check)).to be_a(Hash)
      expect(assigns(:health_check)[:checks]).to be_a(Hash)
      expect(assigns(:health_check)[:checks].keys).to include(:database, :redis, :oauth)
    end

    it "assigns configuration status data" do
      get :index
      expect(assigns(:configuration_status)).to be_a(Hash)
      expect(assigns(:configuration_status).keys).to include(:environment, :database)
    end

    it "renders the correct template" do
      get :index
      expect(response).to render_template("system/health")
    end

    context "when user is not a system administrator" do
      let(:regular_user) { create(:user) }

      before do
        session = regular_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
        cookies.signed[:session_id] = session.id
      end

      it "redirects to root path" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to access this area.")
      end
    end
  end
end

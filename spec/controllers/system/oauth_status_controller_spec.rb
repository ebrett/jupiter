require 'rails_helper'

RSpec.describe System::OauthStatusController, type: :controller do
  let(:system_administrator) { create(:user, :with_system_administrator_role) }

  before do
    # Set up authentication
    session = system_administrator.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id
  end

  describe "GET #index" do
    let!(:active_token) { create(:nationbuilder_token, expires_at: 1.hour.from_now) }
    let!(:expiring_token) { create(:nationbuilder_token, expires_at: 12.hours.from_now) }
    let!(:expired_token) { create(:nationbuilder_token, expires_at: 1.hour.ago) }

    it "returns successful response" do
      get :index
      expect(response).to have_http_status(:success)
    end

    it "assigns token health data" do
      get :index
      expect(assigns(:token_health)).to be_a(Hash)
      expect(assigns(:token_health)[:total_tokens]).to eq(3)
      expect(assigns(:token_health)[:active_tokens]).to eq(2)
      expect(assigns(:token_health)[:expiring_soon]).to eq(2)
    end

    it "assigns performance metrics data" do
      get :index
      expect(assigns(:performance_metrics)).to be_a(Hash)
      expect(assigns(:performance_metrics)[:avg_response_time]).to be_a(Numeric)
      expect(assigns(:performance_metrics)[:success_rate]).to be_a(Numeric)
    end

    it "renders the correct template" do
      get :index
      expect(response).to render_template("system/oauth_status")
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

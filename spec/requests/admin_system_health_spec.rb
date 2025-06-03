require 'rails_helper'

RSpec.describe "Admin System Health", type: :request do
  describe "GET /admin/system_health" do
    context "without authentication" do
      it "redirects to home page when not authenticated" do
        get "/admin/system_health"
        expect(response).to have_http_status(:redirect)
      end
    end
  end
end

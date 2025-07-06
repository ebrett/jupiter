require 'rails_helper'

RSpec.describe "Authentication Pages", type: :request do
  describe "GET /sign-in" do
    it "returns successful response" do
      get "/sign-in"
      expect(response).to have_http_status(:success)
    end

    it "renders sign-in page" do
      get "/sign-in"
      expect(response.body).to include("Sign In")
    end

    it "redirects authenticated users away from sign-in page" do
      user = create(:user)
      sign_in(user)

      get "/sign-in"
      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /sign-up" do
    it "returns successful response" do
      get "/sign-up"
      expect(response).to have_http_status(:success)
    end

    it "renders sign-up page" do
      get "/sign-up"
      expect(response.body).to include("Sign Up")
    end

    it "redirects authenticated users away from sign-up page" do
      user = create(:user)
      sign_in(user)

      get "/sign-up"
      expect(response).to redirect_to(root_path)
    end
  end
end

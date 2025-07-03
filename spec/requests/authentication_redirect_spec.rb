require 'rails_helper'

RSpec.describe "Authentication Redirects", type: :request do
  describe "when accessing protected content" do
    it "redirects unauthenticated users to /sign-in" do
      get "/users"
      expect(response).to redirect_to("/sign-in")
    end

    it "stores the original URL for redirect after authentication" do
      get "/users"
      expect(session[:return_to_after_authenticating]).to include("/users")
    end
  end
end

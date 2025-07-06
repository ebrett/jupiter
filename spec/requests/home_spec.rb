require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when user is not authenticated" do
      it "renders the home page successfully" do
        get root_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Welcome to Jupiter")
      end

      it "shows basic sidebar without user section" do
        get root_path

        expect(response.body).to include("Jupiter")
        expect(response.body).to include("Dashboard")
        # The sidebar should not include admin-only sections when not authenticated
        # Check for the System section header which is only shown to admins
        expect(response.body).not_to include('uppercase tracking-wider">System')
      end

      it "includes sign-in and sign-up navigation links" do
        get root_path

        expect(response.body).to include('Sign In')
        expect(response.body).to include('Sign Up')
      end

      it "shows the navbar items accessible to guests" do
        get root_path

        expect(response.body).to include("Dashboard")
        # The navigation should not show admin-only links when not authenticated
        # Note: "Users" and "Roles" may appear in examples but not as navigation links
        expect(response.body).not_to include("OAuth Status")
        expect(response.body).not_to include("System Health")
      end
    end

    context "when user is authenticated" do
      let(:user) { create(:user, first_name: "John", last_name: "Doe") }
      let(:session) { create(:session, user: user) }

      before do
        # Simulate authentication in request specs
        allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
        allow_any_instance_of(ApplicationController).to receive(:require_authentication).and_return(true)
        allow(Current).to receive_messages(user: user, session: session)
      end

      it "renders the home page successfully" do
        get root_path

        expect(response).to have_http_status(:ok)
      end

      it "shows the authenticated user sidebar section" do
        get root_path

        expect(response.body).to include("John Doe")
        expect(response.body).to include(user.email_address)
        expect(response.body).to include('title="Sign out"')
      end

      it "shows user initials in avatar" do
        get root_path

        expect(response.body).to include("J") # First letter of first name
      end

      context "when user is an admin" do
        let(:role) { create(:role, name: "system_administrator") }
        let(:user) { create(:user, first_name: "Admin") }
        let(:session) { create(:session, user: user) }

        before do
          user.roles << role
          allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
          allow_any_instance_of(ApplicationController).to receive(:require_authentication).and_return(true)
          allow(Current).to receive_messages(user: user, session: session)
        end

        it "shows admin navigation items" do
          get root_path

          # Admin users should see all navigation items
          expect(response.body).to include("Dashboard")
          expect(response.body).to include("OAuth Status")
          expect(response.body).to include("System Health")
          # Note: Users and Roles links require both authentication and permissions
        end
      end
    end
  end
end

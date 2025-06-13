require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:admin_user) { create(:user, :with_system_administrator_role) }
  let(:regular_user) { create(:user, email_address: "test@example.com", first_name: "John", last_name: "Doe") }

  before do
    # Set up authentication
    session = admin_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id
  end

  describe "GET #index" do
    context "when admin user is authenticated" do
      it "renders the index page successfully" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "does not raise NameError for current_user" do
        expect { get :index }.not_to raise_error
      end
    end

    context "when regular user tries to access" do
      before do
        # Change to regular user session
        session = regular_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
        cookies.signed[:session_id] = session.id
      end

      it "redirects with authorization error" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("You are not authorized to perform this action.")
      end
    end

    context "when using Ransack search functionality" do
      it "renders successfully without Ransack errors" do
        expect {
          get :index
        }.not_to raise_error

        expect(response).to have_http_status(:success)
      end

      it "can search by email using Ransack parameters without errors" do
        expect {
          get :index, params: { q: { email_address_cont: "test" } }
        }.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "can search by first name using Ransack parameters without errors" do
        expect {
          get :index, params: { q: { first_name_cont: "John" } }
        }.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "can search by last name using Ransack parameters without errors" do
        expect {
          get :index, params: { q: { last_name_cont: "Doe" } }
        }.not_to raise_error
        expect(response).to have_http_status(:success)
      end

      it "renders page without Ransack configuration errors" do
        expect {
          get :index
        }.not_to raise_error
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET #show" do
    let(:user) { create(:user) }

    it "renders the show page successfully" do
      get :show, params: { id: user.id }
      expect(response).to have_http_status(:success)
    end
  end
end

require 'rails_helper'

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin_user) { create(:user, :with_super_admin_role) }
  let(:regular_user) { create(:user, email_address: "test@example.com", first_name: "John", last_name: "Doe") }

  before do
    # Set up authentication
    session = admin_user.sessions.create!(user_agent: 'test', ip_address: '127.0.0.1')
    cookies.signed[:session_id] = session.id

    # Create a test user to search for
    regular_user
  end

  describe "GET #index" do
    context "when using Ransack search functionality" do
      it "renders successfully without Ransack errors" do
        expect {
          get :index
        }.not_to raise_error

        expect(response).to have_http_status(:success)
      end

      it "can search by email using Ransack parameters" do
        get :index, params: { q: { email_address_cont: "test" } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("test@example.com")
      end

      it "can search by first name using Ransack parameters" do
        get :index, params: { q: { first_name_cont: "John" } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("John")
      end

      it "can search by last name using Ransack parameters" do
        get :index, params: { q: { last_name_cont: "Doe" } }
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Doe")
      end

      it "renders search form elements correctly" do
        get :index
        expect(response.body).to include('name="q[email_address_cont]"')
        expect(response.body).to include('placeholder="Search by email..."')
      end
    end
  end
end

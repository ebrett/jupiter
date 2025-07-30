require 'rails_helper'

RSpec.describe "ReimbursementRequests", type: :request do
  let(:user) { create(:user, :submitter) }
  let(:admin_user) { create(:user, :treasury_admin) }
  let(:viewer_user) { create(:user, :viewer) }
  let(:other_user) { create(:user, :submitter) }

  describe "GET /reimbursement_requests" do
    let!(:user_request) { create(:reimbursement_request, user: user) }
    let!(:other_request) { create(:reimbursement_request, user: other_user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        get reimbursement_requests_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as regular user" do
      before { sign_in_as(user) }

      it "returns success" do
        get reimbursement_requests_path, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)
      end

      it "shows only user's own requests" do
        get reimbursement_requests_path, params: {}, headers: { 'Accept' => 'application/json' }
        expect(response).to have_http_status(:success)

        # Check that the controller assigns the right requests
        assigned_requests = assigns(:reimbursement_requests)
        expect(assigned_requests).to include(user_request)
        expect(assigned_requests).not_to include(other_request)
      end

      it "orders requests by most recent first" do
        newer_request = create(:reimbursement_request, user: user, created_at: 1.hour.ago)
        older_request = create(:reimbursement_request, user: user, created_at: 2.hours.ago)

        get reimbursement_requests_path, params: {}, headers: { 'Accept' => 'application/json' }

        assigned_requests = assigns(:reimbursement_requests).to_a
        expect(assigned_requests.index(newer_request)).to be < assigned_requests.index(older_request)
      end
    end

    context "when authenticated as admin" do
      before { sign_in_as(admin_user) }

      it "shows all requests" do
        get reimbursement_requests_path
        expect(response.body).to include(user_request.title)
        expect(response.body).to include(other_request.title)
      end
    end

    context "when authenticated as viewer without submitter role" do
      before { sign_in_as(viewer_user) }

      it "shows only user's own requests (empty)" do
        get reimbursement_requests_path
        expect(response).to have_http_status(:success)
        expect(response.body).not_to include(user_request.title)
        expect(response.body).not_to include(other_request.title)
      end
    end
  end

  describe "GET /reimbursement_requests/:id" do
    let(:reimbursement_request) { create(:reimbursement_request, user: user) }
    let(:other_request) { create(:reimbursement_request, user: other_user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        get reimbursement_request_path(reimbursement_request)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as owner" do
      before { sign_in_as(user) }

      it "returns success" do
        get reimbursement_request_path(reimbursement_request)
        expect(response).to have_http_status(:success)
      end

      it "displays request details" do
        get reimbursement_request_path(reimbursement_request)
        expect(response.body).to include(reimbursement_request.title)
        expect(response.body).to include(reimbursement_request.description)
      end
    end

    context "when authenticated as different user" do
      before { sign_in_as(other_user) }

      it "returns forbidden" do
        get reimbursement_request_path(reimbursement_request)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as admin" do
      before { sign_in_as(admin_user) }

      it "returns success" do
        get reimbursement_request_path(reimbursement_request)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET /reimbursement_requests/new" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get new_reimbursement_request_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated with submitter role" do
      before { sign_in_as(user) }

      it "returns success" do
        get new_reimbursement_request_path
        expect(response).to have_http_status(:success)
      end

      it "displays the form" do
        get new_reimbursement_request_path
        expect(response.body).to include('form')
        expect(response.body).to include('Title')
        expect(response.body).to include('Description')
      end
    end

    context "when authenticated without submitter role" do
      before { sign_in_as(viewer_user) }

      it "returns forbidden" do
        get new_reimbursement_request_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST /reimbursement_requests" do
    let(:valid_attributes) do
      {
        title: "Conference expenses",
        description: "Travel and accommodation for DA conference",
        amount_cents: 25000,
        currency: "USD",
        expense_date: 1.week.ago.to_date,
        category: "travel",
        priority: "normal"
      }
    end

    let(:invalid_attributes) do
      {
        title: "",
        description: "",
        amount_cents: nil
      }
    end

    context "when not authenticated" do
      it "redirects to sign in" do
        post reimbursement_requests_path, params: { reimbursement_request: valid_attributes }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated with submitter role" do
      before { sign_in_as(user) }

      context "with valid parameters" do
        it "creates a new reimbursement request" do
          expect {
            post reimbursement_requests_path, params: { reimbursement_request: valid_attributes }
          }.to change(ReimbursementRequest, :count).by(1)
        end

        it "assigns the request to the current user" do
          post reimbursement_requests_path, params: { reimbursement_request: valid_attributes }
          expect(ReimbursementRequest.last.user).to eq(user)
        end

        it "sets the status to draft" do
          post reimbursement_requests_path, params: { reimbursement_request: valid_attributes }
          expect(ReimbursementRequest.last.status).to eq('draft')
        end

        it "redirects to the requests index" do
          post reimbursement_requests_path, params: { reimbursement_request: valid_attributes }
          expect(response).to redirect_to(reimbursement_requests_path)
        end

        it "shows success message" do
          post reimbursement_requests_path, params: { reimbursement_request: valid_attributes }
          follow_redirect!
          expect(response.body).to include("successfully")
        end
      end

      context "with invalid parameters" do
        it "does not create a new reimbursement request" do
          expect {
            post reimbursement_requests_path, params: { reimbursement_request: invalid_attributes }
          }.not_to change(ReimbursementRequest, :count)
        end

        it "renders the new template with errors" do
          post reimbursement_requests_path, params: { reimbursement_request: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body).to include("error")
        end
      end

      context "with file uploads" do
        let(:file) { fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf') }
        let(:attributes_with_file) { valid_attributes.merge(receipts: [ file ]) }

        it "attaches the uploaded files" do
          post reimbursement_requests_path, params: { reimbursement_request: attributes_with_file }
          request = ReimbursementRequest.last
          expect(request.receipts).to be_attached
          expect(request.receipts.count).to eq(1)
        end
      end
    end

    context "when authenticated without submitter role" do
      before { sign_in_as(viewer_user) }

      it "returns forbidden" do
        post reimbursement_requests_path, params: { reimbursement_request: valid_attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /reimbursement_requests/:id/edit" do
    let(:reimbursement_request) { create(:reimbursement_request, user: user, status: 'draft') }
    let(:submitted_request) { create(:reimbursement_request, :submitted, user: user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        get edit_reimbursement_request_path(reimbursement_request)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as owner of draft request" do
      before { sign_in_as(user) }

      it "returns success" do
        get edit_reimbursement_request_path(reimbursement_request)
        expect(response).to have_http_status(:success)
      end

      it "displays the edit form" do
        get edit_reimbursement_request_path(reimbursement_request)
        expect(response.body).to include('form')
        expect(response.body).to include(reimbursement_request.title)
      end
    end

    context "when authenticated as owner of submitted request" do
      before { sign_in_as(user) }

      it "returns forbidden" do
        get edit_reimbursement_request_path(submitted_request)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as admin" do
      before { sign_in_as(admin_user) }

      it "returns success for any request" do
        get edit_reimbursement_request_path(submitted_request)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /reimbursement_requests/:id" do
    let(:reimbursement_request) { create(:reimbursement_request, user: user, status: 'draft') }
    let(:submitted_request) { create(:reimbursement_request, :submitted, user: user) }
    let(:new_attributes) { { title: "Updated title", description: "Updated description" } }

    context "when not authenticated" do
      it "redirects to sign in" do
        patch reimbursement_request_path(reimbursement_request), params: { reimbursement_request: new_attributes }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as owner of draft request" do
      before { sign_in_as(user) }

      it "updates the request" do
        patch reimbursement_request_path(reimbursement_request), params: { reimbursement_request: new_attributes }
        reimbursement_request.reload
        expect(reimbursement_request.title).to eq("Updated title")
        expect(reimbursement_request.description).to eq("Updated description")
      end

      it "redirects to the request" do
        patch reimbursement_request_path(reimbursement_request), params: { reimbursement_request: new_attributes }
        expect(response).to redirect_to(reimbursement_request_path(reimbursement_request))
      end
    end

    context "when authenticated as owner of submitted request" do
      before { sign_in_as(user) }

      it "returns forbidden for full update" do
        patch reimbursement_request_path(submitted_request), params: { reimbursement_request: new_attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as admin" do
      before { sign_in_as(admin_user) }

      it "can update any request" do
        patch reimbursement_request_path(submitted_request), params: { reimbursement_request: new_attributes }
        submitted_request.reload
        expect(submitted_request.title).to eq("Updated title")
      end
    end
  end

  describe "DELETE /reimbursement_requests/:id" do
    let(:reimbursement_request) { create(:reimbursement_request, user: user, status: 'draft') }
    let(:submitted_request) { create(:reimbursement_request, :submitted, user: user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        delete reimbursement_request_path(reimbursement_request)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as owner of draft request" do
      before { sign_in_as(user) }

      it "deletes the request" do
        reimbursement_request # ensure it exists
        expect {
          delete reimbursement_request_path(reimbursement_request)
        }.to change(ReimbursementRequest, :count).by(-1)
      end

      it "redirects to the requests index" do
        delete reimbursement_request_path(reimbursement_request)
        expect(response).to redirect_to(reimbursement_requests_path)
      end
    end

    context "when authenticated as owner of submitted request" do
      before { sign_in_as(user) }

      it "returns forbidden" do
        delete reimbursement_request_path(submitted_request)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as system administrator" do
      let(:system_admin) { create(:user, :system_administrator) }

      before { sign_in_as(system_admin) }

      it "can delete any request" do
        submitted_request # ensure it exists
        expect {
          delete reimbursement_request_path(submitted_request)
        }.to change(ReimbursementRequest, :count).by(-1)
      end
    end
  end

  describe "POST /reimbursement_requests/:id/submit" do
    let(:reimbursement_request) { create(:reimbursement_request, user: user, status: 'draft') }
    let(:submitted_request) { create(:reimbursement_request, :submitted, user: user) }

    context "when not authenticated" do
      it "redirects to sign in" do
        post submit_reimbursement_request_path(reimbursement_request)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as owner of draft request" do
      before { sign_in_as(user) }

      it "submits the request" do
        post submit_reimbursement_request_path(reimbursement_request)
        reimbursement_request.reload
        expect(reimbursement_request.status).to eq('submitted')
        expect(reimbursement_request.submitted_at).to be_present
      end

      it "creates an event record" do
        expect {
          post submit_reimbursement_request_path(reimbursement_request)
        }.to change(ReimbursementRequestEvent, :count).by(1)

        event = ReimbursementRequestEvent.last
        expect(event.event_type).to eq('submitted')
        expect(event.user).to eq(user)
      end

      it "redirects with success message" do
        post submit_reimbursement_request_path(reimbursement_request)
        expect(response).to redirect_to(reimbursement_request_path(reimbursement_request))
      end
    end

    context "when authenticated as owner of already submitted request" do
      before { sign_in_as(user) }

      it "returns unprocessable entity" do
        post submit_reimbursement_request_path(submitted_request)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  private

  def sign_in_as(user)
    # Create a session for the user
    user_session = user.sessions.create!(
      ip_address: '127.0.0.1',
      user_agent: 'Test Agent'
    )

    # Stub the authentication to use this session
    allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(user_session)

    # Set up Current to return the user and session
    current_double = double('Current')
    allow(current_double).to receive_messages(user: user, session: user_session)
    allow(Current).to receive_messages(user: user, session: user_session)
    stub_const('Current', current_double)
  end
end

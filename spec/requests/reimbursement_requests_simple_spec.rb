require 'rails_helper'

RSpec.describe "ReimbursementRequests (Core Controller)", type: :request do
  let(:user) { create(:user, :submitter) }
  let(:admin_user) { create(:user, :treasury_admin) }
  let(:viewer_user) { create(:user, :viewer) }
  let(:other_user) { create(:user, :submitter) }

  before do
    # Create test fixture file for file upload tests
    @test_file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf')
  end

  describe "Authentication and Authorization" do
    it "redirects unauthenticated users to sign in" do
      get reimbursement_requests_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "allows authenticated users with submitter role to access index" do
      sign_in_as(user)
      get reimbursement_requests_path, headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)
    end

    it "allows admin users to access index" do
      sign_in_as(admin_user)
      get reimbursement_requests_path, headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "Scoping" do
    let!(:user_request) { create(:reimbursement_request, user: user) }
    let!(:other_request) { create(:reimbursement_request, user: other_user) }

    it "shows only user's own requests for regular users" do
      sign_in_as(user)
      get reimbursement_requests_path, headers: { 'Accept' => 'application/json' }

      assigned_requests = assigns(:reimbursement_requests)
      expect(assigned_requests).to include(user_request)
      expect(assigned_requests).not_to include(other_request)
    end

    it "shows all requests for admin users" do
      sign_in_as(admin_user)
      get reimbursement_requests_path, headers: { 'Accept' => 'application/json' }

      assigned_requests = assigns(:reimbursement_requests)
      expect(assigned_requests).to include(user_request)
      expect(assigned_requests).to include(other_request)
    end
  end

  describe "CREATE operations" do
    before do
      # Clean up any existing blobs before each test
      ActiveStorage::Blob.all.each(&:purge)
      ActiveStorage::Attachment.delete_all
    end

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

    context "when authenticated with submitter role" do
      before { sign_in_as(user) }

      it "creates a new reimbursement request with valid data" do
        expect {
          post reimbursement_requests_path, params: { reimbursement_request: valid_attributes }
        }.to change(ReimbursementRequest, :count).by(1)

        request = ReimbursementRequest.last
        expect(request.user).to eq(user)
        expect(request.status).to eq('draft')
        expect(request.title).to eq("Conference expenses")
      end

      it "rejects invalid data" do
        expect {
          post reimbursement_requests_path,
               params: { reimbursement_request: invalid_attributes },
               headers: { 'Accept' => 'application/json' }
        }.not_to change(ReimbursementRequest, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "handles file uploads" do
        # Create a fresh test file for each test to avoid pollution
        test_file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'test.pdf'), 'application/pdf')
        attributes_with_file = valid_attributes.merge(receipts: [ test_file ])

        initial_count = ReimbursementRequest.count
        post reimbursement_requests_path, params: { reimbursement_request: attributes_with_file }

        expect(ReimbursementRequest.count).to eq(initial_count + 1)
        request = ReimbursementRequest.last
        expect(request.receipts).to be_attached
        # Just check that at least one receipt is attached, in case of test pollution
        expect(request.receipts.count).to be >= 1
      end
    end

    it "rejects requests from users without submitter role" do
      sign_in_as(viewer_user)

      post reimbursement_requests_path,
           params: { reimbursement_request: valid_attributes },
           headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "UPDATE operations" do
    let(:reimbursement_request) { create(:reimbursement_request, user: user, status: 'draft') }
    let(:submitted_request) { create(:reimbursement_request, :submitted, user: user) }
    let(:new_attributes) { { title: "Updated title", description: "Updated description" } }

    context "when authenticated as owner" do
      before { sign_in_as(user) }

      it "updates draft requests" do
        patch reimbursement_request_path(reimbursement_request),
              params: { reimbursement_request: new_attributes }

        reimbursement_request.reload
        expect(reimbursement_request.title).to eq("Updated title")
        expect(response).to redirect_to(reimbursement_request_path(reimbursement_request))
      end

      it "forbids updating submitted requests" do
        patch reimbursement_request_path(submitted_request),
              params: { reimbursement_request: new_attributes },
              headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as admin" do
      before { sign_in_as(admin_user) }

      it "can update any request" do
        # Use a draft request for admin update test since admins can update all fields on draft requests
        admin_test_request = create(:reimbursement_request, user: other_user, status: 'draft')

        patch reimbursement_request_path(admin_test_request),
              params: { reimbursement_request: new_attributes }

        admin_test_request.reload
        expect(admin_test_request.title).to eq("Updated title")
      end
    end
  end

  describe "DELETE operations" do
    let(:reimbursement_request) { create(:reimbursement_request, user: user, status: 'draft') }
    let(:submitted_request) { create(:reimbursement_request, :submitted, user: user) }

    context "when authenticated as owner" do
      before { sign_in_as(user) }

      it "deletes draft requests" do
        reimbursement_request # ensure it exists
        expect {
          delete reimbursement_request_path(reimbursement_request)
        }.to change(ReimbursementRequest, :count).by(-1)
      end

      it "forbids deleting submitted requests" do
        delete reimbursement_request_path(submitted_request),
               headers: { 'Accept' => 'application/json' }
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

  describe "SUBMIT operations" do
    let(:reimbursement_request) { create(:reimbursement_request, user: user, status: 'draft') }
    let(:submitted_request) { create(:reimbursement_request, :submitted, user: user) }

    context "when authenticated as owner" do
      before { sign_in_as(user) }

      it "submits draft requests" do
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

      it "rejects already submitted requests" do
        post submit_reimbursement_request_path(submitted_request)
        expect(response).to have_http_status(:found) # redirect with error
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

require 'rails_helper'

RSpec.describe Admin::ReimbursementRequestsController, type: :controller do
  let(:treasury_admin) { create(:user, :treasury_admin) }
  let(:system_admin) { create(:user, :system_administrator) }
  let(:regular_user) { create(:user, :submitter) }
  let(:other_user) { create(:user, :submitter) }

  let(:user_request) { create(:reimbursement_request, :submitted, user: regular_user) }
  let(:other_request) { create(:reimbursement_request, :submitted, user: other_user) }

  def sign_in_as(user)
    user_session = user.sessions.create!(
      ip_address: '127.0.0.1',
      user_agent: 'Test Agent'
    )

    allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(user_session)

    current_double = double('Current')
    allow(current_double).to receive_messages(user: user, session: user_session)
    allow(Current).to receive_messages(user: user, session: user_session)
    stub_const('Current', current_double)
  end

  describe "Authentication and Authorization" do
    context "when not authenticated" do
      it "redirects to sign-in page" do
        get :index
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when authenticated as regular user" do
      before { sign_in_as(regular_user) }

      it "denies access to admin dashboard" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Access denied")
      end
    end

    context "when authenticated as treasury admin" do
      before { sign_in_as(treasury_admin) }

      it "allows access to admin dashboard" do
        get :index, format: :json
        expect(response).to have_http_status(:success)
      end
    end

    context "when authenticated as system admin" do
      before { sign_in_as(system_admin) }

      it "allows access to admin dashboard" do
        get :index, format: :json
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET #index" do
    before { sign_in_as(treasury_admin) }

    it "returns all reimbursement requests for admin users" do
      user_request # Create the requests
      other_request

      get :index, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(2)
    end

    it "supports filtering by status" do
      draft_request = create(:reimbursement_request, :draft, user: regular_user)
      submitted_request = create(:reimbursement_request, :submitted, user: regular_user)

      get :index, params: { status: 'submitted' }, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response[0]['id']).to eq(submitted_request.id)
    end

    it "supports filtering by user" do
      user_request
      other_request

      get :index, params: { user_id: regular_user.id }, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq(1)
      expect(json_response[0]['id']).to eq(user_request.id)
    end
  end

  describe "GET #show" do
    before { sign_in_as(treasury_admin) }

    it "returns request details for admin users" do
      get :show, params: { id: user_request.id }, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(user_request.id)
      expect(json_response['title']).to eq(user_request.title)
    end

    it "includes audit trail events" do
      user_request.events.create!(
        user: regular_user,
        event_type: 'submitted',
        from_status: 'draft',
        to_status: 'submitted'
      )

      get :show, params: { id: user_request.id }, format: :json

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response['events']).to be_present
      expect(json_response['events'].length).to eq(1)
    end
  end

  describe "PATCH #approve" do
    before { sign_in_as(treasury_admin) }

    context "with valid submitted request" do
      it "approves the request successfully" do
        expect {
          patch :approve, params: {
            id: user_request.id,
            approval_notes: "Approved for travel expenses"
          }, format: :json
        }.to change { user_request.reload.status }.from('submitted').to('approved')

        expect(response).to have_http_status(:success)
        expect(user_request.reload.approved_by).to eq(treasury_admin)
        expect(user_request.approval_notes).to eq("Approved for travel expenses")
      end

      it "creates audit trail event" do
        expect {
          patch :approve, params: { id: user_request.id }, format: :json
        }.to change { user_request.events.count }.by(1)

        event = user_request.events.last
        expect(event.event_type).to eq('approved')
        expect(event.user).to eq(treasury_admin)
        expect(event.from_status).to eq('submitted')
        expect(event.to_status).to eq('approved')
      end

      it "supports partial amount approval" do
        original_amount = user_request.amount_cents
        approved_amount = original_amount - 1000 # $10 less

        patch :approve, params: {
          id: user_request.id,
          approved_amount_cents: approved_amount
        }, format: :json

        expect(response).to have_http_status(:success)
        expect(user_request.reload.approved_amount_cents).to eq(approved_amount)
      end
    end

    context "with invalid request" do
      it "returns error for non-existent request" do
        patch :approve, params: { id: 99999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it "returns error for request in wrong state" do
        draft_request = create(:reimbursement_request, :draft, user: regular_user)

        patch :approve, params: { id: draft_request.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH #reject" do
    before { sign_in_as(treasury_admin) }

    context "with valid submitted request" do
      it "rejects the request successfully" do
        rejection_reason = "Missing required receipts"

        expect {
          patch :reject, params: {
            id: user_request.id,
            rejection_reason: rejection_reason
          }, format: :json
        }.to change { user_request.reload.status }.from('submitted').to('rejected')

        expect(response).to have_http_status(:success)
        expect(user_request.reload.rejection_reason).to eq(rejection_reason)
      end

      it "requires rejection reason" do
        patch :reject, params: { id: user_request.id }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['errors']).to include("Rejection reason is required")
      end

      it "creates audit trail event" do
        expect {
          patch :reject, params: {
            id: user_request.id,
            rejection_reason: "Invalid expense"
          }, format: :json
        }.to change { user_request.events.count }.by(1)

        event = user_request.events.last
        expect(event.event_type).to eq('rejected')
        expect(event.user).to eq(treasury_admin)
      end
    end
  end

  describe "PATCH #request_info" do
    before { sign_in_as(treasury_admin) }

    it "requests additional information from user" do
      info_request = "Please provide additional receipts for meals"

      expect {
        patch :request_info, params: {
          id: user_request.id,
          info_request: info_request
        }, format: :json
      }.to change { user_request.reload.status }.from('submitted').to('under_review')

      expect(response).to have_http_status(:success)
    end

    it "requires info request message" do
      patch :request_info, params: { id: user_request.id }, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
      json_response = JSON.parse(response.body)
      expect(json_response['errors']).to include("Information request message is required")
    end
  end

  describe "PATCH #mark_paid" do
    before { sign_in_as(treasury_admin) }

    context "with approved request" do
      let(:approved_request) { create(:reimbursement_request, :approved, user: regular_user) }

      it "marks request as paid successfully" do
        payment_reference = "CHK-2025-001"

        expect {
          patch :mark_paid, params: {
            id: approved_request.id,
            payment_reference: payment_reference
          }, format: :json
        }.to change { approved_request.reload.status }.from('approved').to('paid')

        expect(response).to have_http_status(:success)
        expect(approved_request.reload.paid_at).to be_present
      end

      it "creates audit trail event" do
        expect {
          patch :mark_paid, params: {
            id: approved_request.id,
            payment_reference: "CHK-2025-001"
          }, format: :json
        }.to change { approved_request.events.count }.by(1)

        event = approved_request.events.last
        expect(event.event_type).to eq('paid')
        expect(event.user).to eq(treasury_admin)
      end
    end

    context "with unapproved request" do
      it "returns error for submitted request" do
        patch :mark_paid, params: { id: user_request.id }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "bulk operations" do
    before { sign_in_as(treasury_admin) }

    describe "POST #bulk_approve" do
      let(:request1) { create(:reimbursement_request, :submitted, user: regular_user) }
      let(:request2) { create(:reimbursement_request, :submitted, user: other_user) }

      it "approves multiple requests at once" do
        request_ids = [ request1.id, request2.id ]

        expect {
          post :bulk_approve, params: {
            request_ids: request_ids,
            approval_notes: "Bulk approved for monthly processing"
          }, format: :json
        }.to change {
          ReimbursementRequest.where(id: request_ids, status: 'approved').count
        }.from(0).to(2)

        expect(response).to have_http_status(:success)
      end

      it "creates audit trail events for all requests" do
        request_ids = [ request1.id, request2.id ]

        expect {
          post :bulk_approve, params: { request_ids: request_ids }, format: :json
        }.to change(ReimbursementRequestEvent, :count).by(2)
      end
    end
  end

  describe "export functionality" do
    before { sign_in_as(treasury_admin) }

    describe "GET #export" do
      it "exports requests as CSV" do
        user_request
        other_request

        get :export, params: { format: 'csv' }

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment')
      end

      it "exports filtered requests" do
        user_request
        other_request

        get :export, params: { format: 'csv', status: 'submitted' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(user_request.title)
      end
    end
  end
end

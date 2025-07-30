require 'rails_helper'

RSpec.describe "ReimbursementRequests HTML Integration", type: :request do
  let(:user) { create(:user, :submitter) }
  let(:admin_user) { create(:user, :treasury_admin) }
  let(:reimbursement_request) { create(:reimbursement_request, user: user) }

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

  describe "HTML template rendering with schema compatibility" do
    context "GET #index as HTML" do
      it "renders the index template with correct schema attributes" do
        sign_in_as(user)
        reimbursement_request # Create the request

        get reimbursement_requests_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(reimbursement_request.user.first_name)
        expect(response.body).to include(reimbursement_request.description[0, 30]) # Truncated in view
        expect(response.body).to include(reimbursement_request.category.humanize)
        expect(response.body).to include(reimbursement_request.currency)

        # Ensure old schema attributes are not referenced
        expect(response.body).not_to include("payee_name")
        expect(response.body).not_to include("purpose")
        expect(response.body).not_to include("expense_category_code")
        expect(response.body).not_to include("amount_requested")
        expect(response.body).not_to include("currency_code")
      end

      it "displays amounts using amount_in_dollars helper" do
        sign_in_as(user)
        request = create(:reimbursement_request,
                        user: user,
                        amount_cents: 12550, # $125.50
                        currency: 'USD')

        get reimbursement_requests_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("$125.50")
      end
    end

    context "GET #show as HTML" do
      it "renders the show template with all new schema attributes" do
        sign_in_as(user)

        get reimbursement_request_path(reimbursement_request)

        expect(response).to have_http_status(:success)

        # Verify new schema attributes are displayed
        expect(response.body).to include(reimbursement_request.description)
        expect(response.body).to include(reimbursement_request.category.humanize)
        expect(response.body).to include(reimbursement_request.currency)
        expect(response.body).to include(reimbursement_request.priority.humanize)
        expect(response.body).to include(reimbursement_request.request_number)
        expect(response.body).to include(reimbursement_request.user.first_name)
        expect(response.body).to include(reimbursement_request.user.last_name)
        expect(response.body).to include(reimbursement_request.user.email_address)

        # Verify expense date is formatted properly
        if reimbursement_request.expense_date
          formatted_date = reimbursement_request.expense_date.strftime("%B %d, %Y")
          expect(response.body).to include(formatted_date)
        end

        # Ensure old schema attributes are not referenced
        expect(response.body).not_to include("undefined method")
        expect(response.body).not_to include("NoMethodError")
      end

      it "handles amount display correctly using amount_in_dollars" do
        sign_in_as(user)
        request = create(:reimbursement_request,
                        user: user,
                        amount_cents: 25099, # $250.99
                        currency: 'EUR')

        get reimbursement_request_path(request)

        expect(response).to have_http_status(:success)
        expect(response.body).to include("$250.99")
        expect(response.body).to include("EUR")
      end
    end

    context "GET #new as HTML" do
      it "renders the new template with form fields using correct schema" do
        sign_in_as(user)

        get new_reimbursement_request_path

        expect(response).to have_http_status(:success)

        # Verify form fields use new schema
        expect(response.body).to include('name="reimbursement_request[title]"')
        expect(response.body).to include('name="reimbursement_request[description]"')
        expect(response.body).to include('name="reimbursement_request[amount_in_dollars]"')
        expect(response.body).to include('name="reimbursement_request[currency]"')
        expect(response.body).to include('name="reimbursement_request[category]"')
        expect(response.body).to include('name="reimbursement_request[expense_date]"')
        expect(response.body).to include('name="reimbursement_request[priority]"')
        expect(response.body).to include('name="reimbursement_request[receipts]"')

        # Ensure old schema field names are not present
        expect(response.body).not_to include('name="reimbursement_request[purpose]"')
        expect(response.body).not_to include('name="reimbursement_request[payee_full_name]"')
        expect(response.body).not_to include('name="reimbursement_request[amount_requested]"')
        expect(response.body).not_to include('name="reimbursement_request[currency_code]"')
        expect(response.body).not_to include('name="reimbursement_request[expense_category_code]"')
      end

      it "includes proper form labels and placeholders" do
        sign_in_as(user)

        get new_reimbursement_request_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Request Title")
        expect(response.body).to include("Description")
        expect(response.body).to include("Amount Requested")
        expect(response.body).to include("Expense Category")
        expect(response.body).to include("Expense Date")
      end
    end

    context "POST #create with HTML redirect" do
      it "creates request with new schema parameters and redirects properly" do
        sign_in_as(user)

        expect {
          post reimbursement_requests_path, params: {
            reimbursement_request: {
              title: "Test Request",
              description: "A test description",
              amount_in_dollars: 150.75,
              currency: "USD",
              category: "travel",
              expense_date: "2025-07-15",
              priority: "normal"
            }
          }
        }.to change(ReimbursementRequest, :count).by(1)

        expect(response).to redirect_to(reimbursement_requests_path)

        created_request = ReimbursementRequest.last
        expect(created_request.title).to eq("Test Request")
        expect(created_request.description).to eq("A test description")
        expect(created_request.amount_cents).to eq(15075) # 150.75 * 100
        expect(created_request.amount_in_dollars).to eq(150.75)
        expect(created_request.currency).to eq("USD")
        expect(created_request.category).to eq("travel")
        expect(created_request.priority).to eq("normal")
      end
    end

    context "error handling in HTML responses" do
      it "renders form errors without template crashes" do
        sign_in_as(user)

        post reimbursement_requests_path, params: {
          reimbursement_request: {
            title: "", # Invalid - required field
            description: "",
            amount_in_dollars: -10 # Invalid - negative amount
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("can't be blank")

        # Ensure error page renders without NoMethodError
        expect(response.body).not_to include("undefined method")
        expect(response.body).not_to include("NoMethodError")
      end
    end
  end

  describe "admin user HTML views" do
    it "allows admin to view all requests in HTML format" do
      sign_in_as(admin_user)
      user_request = create(:reimbursement_request, user: user)
      admin_request = create(:reimbursement_request, user: admin_user)

      get reimbursement_requests_path

      expect(response).to have_http_status(:success)

      # Admin should see both requests
      expect(response.body).to include(user_request.description)
      expect(response.body).to include(admin_request.description)
    end
  end
end

require 'rails_helper'

RSpec.describe InkindDonationsController, type: :controller do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, first_name: 'Admin', last_name: 'User') }
  let(:submitter_user) { create(:user, first_name: 'Test', last_name: 'Submitter') }

  before do
    admin_user.add_role('system_administrator')
    submitter_user.add_role('submitter')
  end

  describe 'authentication' do
    it 'requires authentication for all actions' do
      get :index
      expect(response).to redirect_to(sign_in_path)

      get :new
      expect(response).to redirect_to(sign_in_path)
    end
  end

  describe 'authorization' do
    before { stub_authentication(user) }

    it 'denies access to users without proper roles' do
      # The controller will redirect or show error instead of raising exception
      get :index
      expect(response).to have_http_status(:redirect)
    end
  end

  describe 'GET #index' do
    before { stub_authentication(admin_user) }

    it 'returns http success for admin users' do
      get :index
      expect(response).to have_http_status(:success)
    end

    it 'assigns @inkind_requests' do
      inkind_request = InkindRequest.create!(
        request_type: 'I',
        amount_requested: 100.0,
        form_data: {
          'donor_name' => 'Test Donor',
          'donor_email' => 'donor@example.com',
          'donor_address' => 'Test Address',
          'donation_type' => 'Goods',
          'item_description' => 'Test item',
          'expense_category_code' => 'TEST',
          'donation_date' => '2024-01-01',
          'country' => 'US',
          'submitter_email' => 'test@example.com',
          'submitter_name' => 'Test User'
        }
      )

      get :index
      expect(assigns(:inkind_requests)).to include(inkind_request)
    end
  end

  describe 'GET #new' do
    before { stub_authentication(submitter_user) }

    it 'returns http success for submitter users' do
      get :new
      expect(response).to have_http_status(:success)
    end

    it 'assigns a new @inkind_request' do
      get :new
      expect(assigns(:inkind_request)).to be_a_new(InkindRequest)
      expect(assigns(:inkind_request).request_type).to eq('inkind')
    end

    it 'assigns @expense_categories' do
      category = ExpenseCategory.create!(code: 'TEST', name: 'Test Category')
      get :new
      expect(assigns(:expense_categories)).to include([ 'Test Category', 'TEST' ])
    end
  end

  describe 'POST #create' do
    before { stub_authentication(submitter_user) }

    let(:valid_params) do
      {
        inkind_request: {
          amount_requested: 150.50,
          form_data: {
            donor_name: 'John Doe',
            donor_email: 'john@example.com',
            donor_address: '123 Main St',
            donation_type: 'Services',
            item_description: 'Legal consultation',
            expense_category_code: 'LEGAL_CONSULTING',
            donation_date: '2024-01-15'
          }
        }
      }
    end

    it 'creates a new InkindRequest with valid params' do
      expect {
        post :create, params: valid_params
      }.to change(InkindRequest, :count).by(1)
    end

    it 'sets auto-generated fields' do
      post :create, params: valid_params

      request = InkindRequest.last
      expect(request).to be_present
      expect(request.submitter_email).to eq(submitter_user.email_address)
      expect(request.submitter_name).to eq("#{submitter_user.first_name} #{submitter_user.last_name}".strip)
      expect(request.country).to eq('US')
      expect(request.request_type).to eq('inkind')
    end

    it 'redirects to index on successful creation' do
      post :create, params: valid_params
      expect(response).to redirect_to(inkind_donations_path)
      expect(flash[:notice]).to eq('In-kind donation submitted successfully.')
    end

    it 'renders new template on validation failure' do
      invalid_params = valid_params.deep_dup
      invalid_params[:inkind_request][:form_data][:donor_email] = 'invalid-email'

      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:new)
    end
  end

  describe 'GET #show' do
    let(:inkind_request) do
      InkindRequest.create!(
        request_type: 'I',
        amount_requested: 100.0,
        form_data: {
          'donor_name' => 'Test Donor',
          'donor_email' => 'donor@example.com',
          'donor_address' => 'Test Address',
          'donation_type' => 'Goods',
          'item_description' => 'Test item',
          'expense_category_code' => 'TEST',
          'donation_date' => '2024-01-01',
          'country' => 'US',
          'submitter_email' => 'test@example.com',
          'submitter_name' => 'Test User'
        }
      )
    end

    before { stub_authentication(admin_user) }

    it 'returns http success for admin users' do
      get :show, params: { id: inkind_request.id }
      expect(response).to have_http_status(:success)
    end

    it 'assigns @inkind_request' do
      get :show, params: { id: inkind_request.id }
      expect(assigns(:inkind_request)).to eq(inkind_request)
    end
  end

  describe 'GET #export' do
    before { stub_authentication(admin_user) }

    let!(:inkind_request) do
      InkindRequest.create!(
        request_type: 'I',
        amount_requested: 100.0,
        form_data: {
          'donor_name' => 'Test Donor',
          'donor_email' => 'donor@example.com',
          'donor_address' => 'Test Address',
          'donation_type' => 'Goods',
          'item_description' => 'Test item',
          'expense_category_code' => 'TEST',
          'donation_date' => '2024-01-01',
          'country' => 'US',
          'submitter_email' => 'test@example.com',
          'submitter_name' => 'Test User'
        }
      )
    end

    it 'generates CSV export' do
      get :export, format: :csv

      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('inkind_donations_')
    end

    it 'includes correct CSV headers' do
      get :export, format: :csv

      csv_content = response.body
      lines = csv_content.split("\n")
      headers = lines.first.split(',')

      expect(headers).to include('Timestamp', 'Donor Name', 'Fair Market Value')
    end
  end
end

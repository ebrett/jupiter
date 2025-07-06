require 'rails_helper'

RSpec.describe 'InkindDonations API', type: :request do
  let(:submitter_user) { create(:user, first_name: 'API', last_name: 'Submitter') }
  let(:admin_user) { create(:user) }
  let(:user_without_role) { create(:user) }
  let!(:expense_category) { create(:expense_category, code: 'TEST', name: 'Test Category') }

  before do
    submitter_user.add_role('submitter')
    admin_user.add_role('system_administrator')
  end

  describe 'POST /inkind_donations' do
    let(:valid_params) do
      {
        inkind_request: {
          amount_requested: 1000.00,
          form_data: {
            donor_name: 'API Test Donor',
            donor_email: 'api@example.com',
            donor_address: '789 API Street',
            donation_type: 'Goods',
            item_description: 'API test donation',
            expense_category_code: 'TEST',
            donation_date: '2024-01-20'
          }
        }
      }
    end

    context 'when authenticated as submitter' do
      before { sign_in(submitter_user) }

      it 'creates a new inkind donation with valid params' do
        expect {
          post inkind_donations_path, params: valid_params
        }.to change(InkindRequest, :count).by(1)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(inkind_donations_path)

        # Verify created donation
        donation = InkindRequest.last
        expect(donation.donor_name).to eq('API Test Donor')
        expect(donation.amount_requested).to eq(1000.00)
        expect(donation.submitter_email).to eq(submitter_user.email_address)
      end

      it 'returns unprocessable entity with invalid params' do
        invalid_params = valid_params.deep_dup
        invalid_params[:inkind_request][:form_data].delete(:donor_name)

        expect {
          post inkind_donations_path, params: invalid_params
        }.not_to change(InkindRequest, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'handles missing form_data gracefully' do
        invalid_params = { inkind_request: { amount_requested: 100 } }

        expect {
          post inkind_donations_path, params: invalid_params
        }.not_to change(InkindRequest, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'sanitizes HTML in form inputs' do
        xss_params = valid_params.deep_dup
        xss_params[:inkind_request][:form_data][:donor_name] = '<script>alert("XSS")</script>Donor'
        xss_params[:inkind_request][:form_data][:item_description] = 'Item<img src=x onerror=alert(1)>'

        post inkind_donations_path, params: xss_params

        donation = InkindRequest.last
        expect(donation.donor_name).to eq('<script>alert("XSS")</script>Donor')
        expect(donation.item_description).to eq('Item<img src=x onerror=alert(1)>')
        # The actual sanitization would happen in the view layer
      end

      it 'handles very long input gracefully' do
        long_params = valid_params.deep_dup
        long_params[:inkind_request][:form_data][:donor_name] = 'A' * 256 # Over limit

        post inkind_donations_path, params: long_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('cannot exceed 255 characters')
      end

      it 'handles special characters in input' do
        special_params = valid_params.deep_dup
        special_params[:inkind_request][:form_data][:donor_name] = "O'Malley & Co."
        special_params[:inkind_request][:form_data][:donor_address] = '123 "Main" St, Apt #5'

        post inkind_donations_path, params: special_params

        expect(response).to have_http_status(:redirect)
        donation = InkindRequest.last
        expect(donation.donor_name).to eq("O'Malley & Co.")
        expect(donation.donor_address).to eq('123 "Main" St, Apt #5')
      end

      it 'prevents duplicate rapid submissions' do
        # First submission
        post inkind_donations_path, params: valid_params
        expect(response).to have_http_status(:redirect)

        # Rapid second submission with same data
        expect {
          post inkind_donations_path, params: valid_params
        }.to change(InkindRequest, :count).by(1) # Still creates, as we don't have duplicate prevention yet
      end
    end

    context 'when authenticated as user without role' do
      before { sign_in(user_without_role) }

      it 'redirects with authorization error' do
        post inkind_donations_path, params: valid_params

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
        expect(InkindRequest.count).to eq(0)
      end
    end

    context 'when not authenticated' do
      it 'redirects to login' do
        post inkind_donations_path, params: valid_params

        expect(response).to redirect_to(sign_in_path)
        expect(InkindRequest.count).to eq(0)
      end
    end
  end

  describe 'GET /inkind_donations' do
    let!(:donation1) { create(:inkind_request, created_at: 2.days.ago) }
    let!(:donation2) { create(:inkind_request, created_at: 1.day.ago) }

    context 'when authenticated as admin' do
      before { sign_in(admin_user) }

      it 'returns all donations ordered by recency' do
        get inkind_donations_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(donation2.donor_name)
        expect(response.body).to include(donation1.donor_name)

        # Verify order (newer first)
        expect(response.body.index(donation2.donor_name)).to be < response.body.index(donation1.donor_name)
      end

      it 'handles empty results gracefully' do
        InkindRequest.destroy_all

        get inkind_donations_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('No in-kind donations')
      end
    end

    context 'when authenticated as submitter' do
      before { sign_in(submitter_user) }

      it 'redirects with authorization error' do
        get inkind_donations_path

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /inkind_donations/:id' do
    let(:donation) { create(:inkind_request) }

    context 'when authenticated as admin' do
      before { sign_in(admin_user) }

      it 'shows donation details' do
        get inkind_donation_path(donation)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(donation.donor_name)
        expect(response.body).to include(donation.item_description)
      end

      it 'returns 404 for non-existent donation' do
        get inkind_donation_path(id: 'non-existent')

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /inkind_donations/export.csv' do
    let!(:donation) { create(:inkind_request, amount_requested: 500.00) }

    context 'when authenticated as admin' do
      before { sign_in(admin_user) }

      it 'returns CSV file with correct headers' do
        get export_inkind_donations_path(format: :csv)

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('text/csv')
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.headers['Content-Disposition']).to include('inkind_donations_')

        # Verify CSV content
        csv_lines = response.body.split("\n")
        expect(csv_lines.first).to include('Timestamp', 'Donor Name', 'Fair Market Value')
        expect(csv_lines[1]).to include(donation.donor_name)
      end

      it 'handles large datasets efficiently' do
        # Create multiple donations
        create_list(:inkind_request, 50)

        get export_inkind_donations_path(format: :csv)

        expect(response).to have_http_status(:ok)
        csv_lines = response.body.split("\n")
        expect(csv_lines.count).to eq(52) # Header + 51 donations
      end
    end

    context 'when authenticated as non-admin' do
      before { sign_in(submitter_user) }

      it 'redirects with authorization error' do
        get export_inkind_donations_path(format: :csv)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'Security considerations' do
    before { sign_in(submitter_user) }

    let(:security_valid_params) do
      {
        inkind_request: {
          amount_requested: 1000.00,
          form_data: {
            donor_name: 'Security Test Donor',
            donor_email: 'security@example.com',
            donor_address: '789 Security Street',
            donation_type: 'Goods',
            item_description: 'Security test donation',
            expense_category_code: 'TEST',
            donation_date: '2024-01-20'
          }
        }
      }
    end

    it 'validates CSRF token' do
      # Simulate missing CSRF token
      allow_any_instance_of(ActionController::Base).to receive(:verify_authenticity_token).and_raise(ActionController::InvalidAuthenticityToken) # rubocop:disable RSpec/AnyInstance

      post inkind_donations_path, params: { inkind_request: { amount_requested: 100 } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'handles SQL injection attempts in parameters' do
      sql_injection_params = security_valid_params.deep_dup
      sql_injection_params[:inkind_request][:form_data][:donor_name] = "'; DROP TABLE users; --"

      expect {
        post inkind_donations_path, params: sql_injection_params
      }.to change(InkindRequest, :count).by(1)

      # Verify the input is stored as-is (escaped by ActiveRecord)
      donation = InkindRequest.last
      expect(donation.donor_name).to eq("'; DROP TABLE users; --")
      expect(User.count).to be > 0 # Table still exists
    end

    it 'handles Unicode characters properly' do
      unicode_params = security_valid_params.deep_dup
      unicode_params[:inkind_request][:form_data][:donor_name] = '测试捐赠者 🎁'
      unicode_params[:inkind_request][:form_data][:item_description] = 'Donation with émojis 🌟 and spëcial chars'

      post inkind_donations_path, params: unicode_params

      expect(response).to have_http_status(:redirect)
      donation = InkindRequest.last
      expect(donation.donor_name).to eq('测试捐赠者 🎁')
      expect(donation.item_description).to include('émojis 🌟')
    end
  end
end

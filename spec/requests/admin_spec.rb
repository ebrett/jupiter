require 'rails_helper'

RSpec.describe 'Admin', type: :request do
  let(:user) { User.create!(email_address: 'test@example.com', password: 'password') }

  it 'redirects unauthenticated users to the sign in page' do
    get admin_path
    expect(response).to redirect_to(new_session_path)
  end

  it 'allows authenticated users to access the admin page' do
    # Simulate login
    post session_path, params: { email_address: user.email_address, password: 'password' }
    follow_redirect!
    get admin_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Admin Dashboard')
  end
end

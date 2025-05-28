require 'rails_helper'

RSpec.describe 'Home', type: :request do
  it 'allows access to the home page without authentication' do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Welcome to Jupiter')
  end
end

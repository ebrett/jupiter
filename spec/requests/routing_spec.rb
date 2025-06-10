require 'rails_helper'

describe 'Routing and routes.rb loading', type: :request do
  it 'loads the routes file and routes root path' do
    expect { get '/' }.not_to raise_error
    expect(response).to be_successful
  end
end 
module AuthenticationHelpers
  def sign_in(user)
    # For request specs, we need to actually perform the login
    post session_path, params: {
      email_address: user.email_address,
      password: 'password' # Default password from factory
    }
  end

  def sign_in_as_nationbuilder_user(user)
    # Simulate NationBuilder OAuth callback
    token_service = instance_double(NationbuilderTokenExchangeService)
    allow(NationbuilderTokenExchangeService).to receive(:new).and_return(token_service)
    allow(token_service).to receive(:exchange_code_for_token).and_return({
      access_token: "test_token",
      refresh_token: "refresh_token",
      expires_in: 3600,
      scope: "default"
    })

    profile_data = {
      id: user.nationbuilder_uid,
      email: user.email_address,
      first_name: user.first_name,
      last_name: user.last_name,
      tags: [ "member" ],
      raw_data: {}
    }

    user_service = instance_double(NationbuilderUserService)
    allow(NationbuilderUserService).to receive(:new).and_return(user_service)
    allow(user_service).to receive_messages(
      fetch_user_profile: profile_data,
      find_or_create_user: user
    )

    get "/auth/nationbuilder/callback", params: { code: "test_code" }
  end

  # For controller specs that need to bypass authentication
  def stub_authentication(user)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:require_authentication).and_return(true)

    session = user.sessions.create!(ip_address: '127.0.0.1', user_agent: 'Test')
    allow(Current).to receive_messages(user: user, session: session)
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :controller
end

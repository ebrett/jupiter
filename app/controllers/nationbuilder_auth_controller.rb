class NationbuilderAuthController < ApplicationController
  allow_unauthenticated_access only: [ :redirect, :callback ]

  before_action :resume_session

  def redirect
    client = Oauth2Client.new(
      client_id: ENV["NATIONBUILDER_CLIENT_ID"],
      client_secret: ENV["NATIONBUILDER_CLIENT_SECRET"],
      redirect_uri: ENV["NATIONBUILDER_REDIRECT_URI"],
      scopes: [ "people:read", "sites:read" ] # Example scopes, adjust as needed
    )
    redirect_to client.authorization_url(state: session.id), allow_other_host: true
  end

  def callback
    return handle_oauth_error if params[:error]
    return handle_missing_code if params[:code].blank?

    # Handle both authenticated and unauthenticated users
    if Current.user
      # Existing user linking their NationBuilder account
      exchange_code_for_token
    else
      # New user signing in via NationBuilder
      authenticate_with_nationbuilder
    end
  rescue NationbuilderTokenExchangeService::TokenExchangeError => e
    redirect_to new_session_path, alert: "NationBuilder authentication failed: #{e.message}"
  rescue NationbuilderUserService::UserCreationError => e
    redirect_to new_session_path, alert: "Unable to create account: #{e.message}"
  rescue => e
    Rails.logger.error "OAuth callback error: #{e.message}\n#{e.backtrace.join("\n")}"
    redirect_to new_session_path, alert: "Authentication failed. Please try again."
  end

  private

  def handle_oauth_error
    error_message = params[:error_description] || params[:error]
    redirect_to root_path, alert: "OAuth error: #{error_message}"
  end

  def handle_missing_code
    redirect_to root_path, alert: "No authorization code received."
  end

  def exchange_code_for_token
    token_data = token_exchange_service.exchange_code_for_token(params[:code])
    update_user_token(token_data)
    redirect_to root_path, notice: "Nationbuilder authentication successful."
  end

  def token_exchange_service
    NationbuilderTokenExchangeService.new(
      client_id: ENV["NATIONBUILDER_CLIENT_ID"],
      client_secret: ENV["NATIONBUILDER_CLIENT_SECRET"],
      redirect_uri: ENV["NATIONBUILDER_REDIRECT_URI"]
    )
  end

  def authenticate_with_nationbuilder
    # Exchange code for tokens
    token_data = token_exchange_service.exchange_code_for_token(params[:code])
    
    # Fetch user profile from NationBuilder
    user_service = NationbuilderUserService.new(access_token: token_data[:access_token])
    profile_data = user_service.fetch_user_profile
    
    # Find or create user from profile
    user = user_service.find_or_create_user(profile_data)
    
    # Store tokens for the user
    store_user_tokens(user, token_data)
    
    # Start session for the user
    start_new_session_for(user)
    
    redirect_to root_path, notice: "Successfully signed in with NationBuilder!"
  end

  def store_user_tokens(user, token_data)
    nationbuilder_token = user.nationbuilder_tokens.first_or_initialize
    nationbuilder_token.update!(
      access_token: token_data[:access_token],
      refresh_token: token_data[:refresh_token],
      expires_at: Time.current + token_data[:expires_in].to_i.seconds,
      scope: token_data[:scope],
      raw_response: token_data
    )
  end

  def update_user_token(token_data)
    store_user_tokens(Current.user, token_data)
  end
end

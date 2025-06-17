class NationbuilderAuthController < ApplicationController
  include OauthHelper

  allow_unauthenticated_access only: [ :redirect, :callback ]

  before_action :resume_session

  def redirect
    client = Oauth2Client.new(
      client_id: ENV["NATIONBUILDER_CLIENT_ID"],
      client_secret: ENV["NATIONBUILDER_CLIENT_SECRET"],
      redirect_uri: ENV["NATIONBUILDER_REDIRECT_URI"],
      scopes: [ "default" ] # NationBuilder standard OAuth scope
    )
    redirect_to client.authorization_url(state: session.id), allow_other_host: true
  end

  def callback
    return handle_oauth_error if params[:error]
    return handle_missing_code if params[:code].blank?

    # Handle both authenticated and unauthenticated users
    if Current.user
      # Existing user linking their NationBuilder account
      handle_account_linking
    else
      # New user signing in via NationBuilder
      authenticate_with_nationbuilder
    end
  rescue NationbuilderTokenExchangeService::TokenExchangeError => e
    Rails.logger.error "NationBuilder OAuth: TokenExchangeError - #{e.message}"

    # Provide user-friendly error messages based on the error
    user_message = case e.message
    when /invalid_grant/
      "The authorization code has expired or is invalid. Please try signing in again."
    when /redirect_uri_mismatch/
      "Configuration error: The redirect URL doesn't match. Please contact support."
    when /invalid_client/
      "Configuration error: Invalid client credentials. Please contact support."
    when /cloudflare_challenge/
      "NationBuilder OAuth is currently blocked by Cloudflare security. Please contact the NationBuilder site administrator to whitelist OAuth API endpoints."
    else
      "Unable to complete sign-in with NationBuilder. Please try again."
    end

    flash[:alert] = user_message
    redirect_to new_session_path
  rescue NationbuilderUserService::UserCreationError => e
    Rails.logger.error "NationBuilder OAuth: UserCreationError - #{e.message}"
    flash[:alert] = "Unable to create your account. Please try again or contact support."
    redirect_to new_session_path
  rescue NationbuilderOauthErrors::NetworkError => e
    Rails.logger.error "NationBuilder OAuth: NetworkError - #{e.message}"
    flash[:alert] = "Unable to connect to NationBuilder. Please check your connection and try again."
    redirect_to new_session_path
  rescue NationbuilderOauthErrors::RateLimitError => e
    Rails.logger.error "NationBuilder OAuth: RateLimitError - #{e.message}"
    flash[:alert] = "Too many sign-in attempts. Please wait a few minutes and try again."
    redirect_to new_session_path
  rescue => e
    Rails.logger.error "OAuth callback error: #{e.class.name} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash[:alert] = "An unexpected error occurred during sign-in. Please try again."
    redirect_to new_session_path
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

  def handle_account_linking
    # Exchange code for tokens
    token_data = token_exchange_service.exchange_code_for_token(params[:code])

    # Fetch user profile from NationBuilder
    user_service = NationbuilderUserService.new(access_token: token_data[:access_token])
    profile_data = user_service.fetch_user_profile

    # Check if this NationBuilder account is already linked to another user
    nationbuilder_uid = profile_data["id"].to_s
    existing_user = User.find_by(nationbuilder_uid: nationbuilder_uid)

    if existing_user && existing_user.id != Current.user.id
      # This NationBuilder account is already linked to another user
      flash[:alert] = "This NationBuilder account is already linked to another user."
      redirect_to account_nationbuilder_link_path
      return
    end

    # Update current user with NationBuilder info
    Current.user.update!(
      nationbuilder_uid: nationbuilder_uid,
      first_name: Current.user.first_name.presence || profile_data["first_name"],
      last_name: Current.user.last_name.presence || profile_data["last_name"]
    )

    # Store tokens
    store_user_tokens(Current.user, token_data)

    # Clear linking flag
    session.delete(:linking_nationbuilder)

    flash[:notice] = "Successfully linked your NationBuilder account!"
    redirect_to account_nationbuilder_link_path
  end
end

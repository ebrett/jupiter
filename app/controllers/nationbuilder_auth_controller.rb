class NationbuilderAuthController < ApplicationController
  include OauthHelper
  include FeatureFlaggable

  allow_unauthenticated_access only: [ :redirect, :callback ]

  before_action :resume_session
  before_action :check_nationbuilder_feature_flag

  def redirect
    client = Oauth2Client.new(
      client_id: ENV["NATIONBUILDER_CLIENT_ID"],
      client_secret: ENV["NATIONBUILDER_CLIENT_SECRET"],
      redirect_uri: ENV["NATIONBUILDER_REDIRECT_URI"],
      scopes: [ "default" ] # NationBuilder standard OAuth scope
    )
    
    # Generate a secure OAuth state parameter and store it in the session
    oauth_state = SecureRandom.hex(16)
    session[:oauth_state] = oauth_state
    
    redirect_to client.authorization_url(state: oauth_state), allow_other_host: true
  end

  def callback
    # Check if this is a return from completed challenge
    if params[:challenge_completed] == "true"
      return handle_challenge_completed_callback
    end

    return handle_oauth_error if params[:error]
    return handle_missing_code if params[:code].blank?

    # Validate OAuth state parameter for CSRF protection
    if params[:state] != session[:oauth_state]
      Rails.logger.error "OAuth state mismatch - expected: #{session[:oauth_state]}, got: #{params[:state]}"
      flash[:alert] = "Security validation failed. Please try signing in again."
      redirect_to sign_in_path and return
    end

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

    # Check if this is a Cloudflare challenge and feature flag is enabled
    if e.message == "cloudflare_challenge" && e.data[:challenge] && cloudflare_challenge_handling_enabled?
      return handle_cloudflare_challenge(e.data[:challenge])
    end

    # Provide user-friendly error messages based on the error
    user_message = case e.message
    when /invalid_grant/
      "The authorization code has expired or is invalid. Please try signing in again."
    when /redirect_uri_mismatch/
      "Configuration error: The redirect URL doesn't match. Please contact support."
    when /invalid_client/
      "Configuration error: Invalid client credentials. Please contact support."
    else
      "Unable to complete sign-in with NationBuilder. Please try again."
    end

    flash[:alert] = user_message
    redirect_to sign_in_path
  rescue NationbuilderUserService::UserCreationError => e
    Rails.logger.error "NationBuilder OAuth: UserCreationError - #{e.message}"
    flash[:alert] = "Unable to create your account. Please try again or contact support."
    redirect_to sign_in_path
  rescue NationbuilderOauthErrors::NetworkError => e
    Rails.logger.error "NationBuilder OAuth: NetworkError - #{e.message}"
    flash[:alert] = "Unable to connect to NationBuilder. Please check your connection and try again."
    redirect_to sign_in_path
  rescue NationbuilderOauthErrors::RateLimitError => e
    Rails.logger.error "NationBuilder OAuth: RateLimitError - #{e.message}"
    flash[:alert] = "Too many sign-in attempts. Please wait a few minutes and try again."
    redirect_to sign_in_path
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error "NationBuilder OAuth: Network timeout - #{e.message}"
    flash[:alert] = "Unable to connect to NationBuilder. Please check your connection and try again."
    redirect_to sign_in_path
  rescue => e
    Rails.logger.error "OAuth callback error: #{e.class.name} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash[:alert] = "An unexpected error occurred during sign-in. Please try again."
    redirect_to sign_in_path
  end

  private

  def cloudflare_challenge_handling_enabled?
    flag = FeatureFlag.find_by(name: "cloudflare_challenge_handling")
    return false unless flag&.enabled?

    # If user is logged in, check if they have access to the feature
    if current_user
      feature_enabled?("cloudflare_challenge_handling")
    else
      # For unauthenticated users (OAuth flow), check global flag only
      true
    end
  end

  def check_nationbuilder_feature_flag
    # For OAuth flows, we check if the feature is globally enabled
    # If user is logged in, we also check if they have access to the feature
    flag = FeatureFlag.find_by(name: "nationbuilder_signin")

    unless flag&.enabled?
      redirect_to sign_in_path, alert: "NationBuilder sign-in is currently unavailable."
      return false
    end

    # If user is logged in, check if they have access to the feature
    if current_user && !feature_enabled?("nationbuilder_signin")
      redirect_to sign_in_path, alert: "NationBuilder sign-in is currently unavailable."
      return false
    end

    true
  end

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

  def handle_cloudflare_challenge(cloudflare_challenge)
    Rails.logger.info "NationBuilder OAuth: Handling Cloudflare challenge"

    # Use the OAuth state from params (which should match session[:oauth_state])
    oauth_state = params[:state]

    # Create challenge record
    challenge = CloudflareChallenge.create!(
      challenge_id: SecureRandom.uuid,
      challenge_type: cloudflare_challenge.type,
      challenge_data: cloudflare_challenge.challenge_data,
      oauth_state: oauth_state,
      original_params: params.permit!.to_h.except("controller", "action"),
      session_id: request.session_options[:id] || SecureRandom.hex(16),
      user: Current.user,
      expires_at: 15.minutes.from_now
    )

    Rails.logger.info "NationBuilder OAuth: Created challenge #{challenge.challenge_id}"

    # Redirect to challenge display page
    redirect_to cloudflare_challenge_path(challenge.challenge_id)
  end

  def handle_challenge_completed_callback
    Rails.logger.info "NationBuilder OAuth: Handling challenge completion callback"

    # Find the challenge by OAuth state
    challenge = CloudflareChallenge.active.find_by(oauth_state: params[:state])

    if challenge.nil?
      Rails.logger.error "NationBuilder OAuth: Challenge not found for state #{params[:state]}"
      flash[:alert] = "Unable to complete sign-in. Please try again."
      redirect_to sign_in_path
      return
    end

    Rails.logger.info "NationBuilder OAuth: Challenge #{challenge.challenge_id} validated, resuming OAuth flow"

    # Resume normal OAuth flow
    # The token exchange will succeed this time as the challenge has been completed
    if challenge.user.present?
      # User was already authenticated, continue with account linking
      handle_account_linking
    else
      # New user authentication
      authenticate_with_nationbuilder
    end
  end
end

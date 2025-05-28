class NationbuilderAuthController < ApplicationController
  allow_unauthenticated_access only: [:redirect, :callback]

  before_action :resume_session

  def redirect
    client = Oauth2Client.new(
      client_id: ENV['NATIONBUILDER_CLIENT_ID'],
      client_secret: ENV['NATIONBUILDER_CLIENT_SECRET'],
      redirect_uri: ENV['NATIONBUILDER_REDIRECT_URI'],
      scopes: ['people:read', 'sites:read'] # Example scopes, adjust as needed
    )
    redirect_to client.authorization_url(state: session.id), allow_other_host: true
  end

  def callback
    return redirect_to new_session_path unless Current.user
    return handle_oauth_error if params[:error]
    return handle_missing_code if params[:code].blank?

    exchange_code_for_token
  rescue NationbuilderTokenExchangeService::TokenExchangeError => e
    redirect_to root_path, alert: "Nationbuilder token exchange failed: #{e.message}"
  rescue => e
    redirect_to root_path, alert: "Unexpected error: #{e.message}"
  end

  private

  def handle_oauth_error
    error_message = params[:error_description] || params[:error]
    redirect_to root_path, alert: "OAuth error: #{error_message}"
  end

  def handle_missing_code
    redirect_to root_path, alert: 'No authorization code received.'
  end

  def exchange_code_for_token
    token_data = token_exchange_service.exchange_code_for_token(params[:code])
    update_user_token(token_data)
    redirect_to root_path, notice: 'Nationbuilder authentication successful.'
  end

  def token_exchange_service
    NationbuilderTokenExchangeService.new(
      client_id: ENV['NATIONBUILDER_CLIENT_ID'],
      client_secret: ENV['NATIONBUILDER_CLIENT_SECRET'],
      redirect_uri: ENV['NATIONBUILDER_REDIRECT_URI']
    )
  end

  def update_user_token(token_data)
    nationbuilder_token = Current.user.nationbuilder_tokens.first_or_initialize
    nationbuilder_token.update!(
      access_token: token_data[:access_token],
      refresh_token: token_data[:refresh_token],
      expires_at: Time.current + token_data[:expires_in].to_i.seconds,
      scope: token_data[:scope],
      raw_response: token_data
    )
  end
end 
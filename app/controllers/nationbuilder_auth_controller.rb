class NationbuilderAuthController < ApplicationController
  allow_unauthenticated_access only: [:redirect, :callback]

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
    if params[:error]
      redirect_to root_path, alert: "OAuth error: #{params[:error_description] || params[:error]}"
      return
    end

    code = params[:code]
    if code.blank?
      redirect_to root_path, alert: 'No authorization code received.'
      return
    end

    # Token exchange will be implemented in the next subtask
    head :ok
  end
end 
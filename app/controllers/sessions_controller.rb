class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }
  before_action :redirect_if_authenticated, only: :new

  def new
  end

  def create
    permitted = params.permit(:email_address, :password, :remember_me, :authenticity_token, :commit)

    # Check if required parameters are present
    if permitted[:email_address].blank? || permitted[:password].blank?
      redirect_to sign_in_path(email_address: permitted[:email_address]), alert: "Try another email address or password."
      return
    end

    if user = User.authenticate_by(permitted.slice(:email_address, :password))
      remember_me = permitted[:remember_me] == "1"
      start_new_session_for user, remember_me: remember_me
      redirect_to after_authentication_url
    else
      redirect_to sign_in_path(email_address: permitted[:email_address]), alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path
  end

  private

  def redirect_if_authenticated
    redirect_to root_path if authenticated?
  end
end

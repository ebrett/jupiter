class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [ :create ]

  def create
    @user = User.new(registration_params)

    if @user.save
      # Send verification email for email/password users
      if @user.email_password_user?
        @user.send_verification_email
        redirect_to root_path, notice: "Account created! Please check your email to verify your account."
      else
        # For NationBuilder users (if any), auto-verify and log in
        start_new_session_for @user
        redirect_to after_authentication_url, notice: "Welcome to Jupiter!"
      end
    else
      # Handle registration errors - redirect back to sign-up with preserved data
      error_message = @user.errors.full_messages.join(", ")
      redirect_to sign_up_path(
        first_name: registration_params[:first_name],
        last_name: registration_params[:last_name],
        email_address: registration_params[:email_address]
      ), alert: error_message
    end
  end

  private

  def registration_params
    params.permit(:email_address, :password, :password_confirmation, :first_name, :last_name)
  end
end

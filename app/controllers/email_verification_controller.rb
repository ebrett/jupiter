class EmailVerificationController < ApplicationController
  allow_unauthenticated_access only: [ :verify ]
  before_action :find_user_by_token, only: [ :verify ]
  before_action :require_current_user, only: [ :resend ]

  def verify
    if @user.nil?
      redirect_to new_session_path, alert: "Invalid verification link. Please try again or contact support."
      return
    end

    if @user.email_verified?
      redirect_to root_path, notice: "Your email is already verified!"
      return
    end

    if @user.verification_expired?
      redirect_to new_session_path, alert: "Verification link has expired. Please request a new one."
      return
    end

    @user.verify_email!

    # Automatically log in the user after verification (default session duration)
    start_new_session_for(@user)

    redirect_to root_path, notice: "Email verified successfully! Welcome to Jupiter."
  rescue => e
    Rails.logger.error "Email verification failed for token #{params[:token]}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n") if Rails.env.test?
    redirect_to new_session_path, alert: "Verification failed. Please try again."
  end

  def resend
    unless Current.user.email_password_user?
      redirect_to root_path, alert: "Verification emails are only for email/password accounts."
      return
    end

    if Current.user.email_verified?
      redirect_to root_path, notice: "Your email is already verified!"
      return
    end

    unless Current.user.can_resend_verification?
      redirect_to root_path, alert: "Please wait before requesting another verification email."
      return
    end

    if Current.user.send_verification_email
      redirect_to root_path, notice: "Verification email sent! Please check your inbox."
    else
      redirect_to root_path, alert: "Failed to send verification email. Please try again later."
    end
  end

  private

  def find_user_by_token
    @user = User.find_by_verification_token(params[:token]) if params[:token].present?
  end

  def require_current_user
    redirect_to new_session_path, alert: "Please log in first." unless Current.user
  end
end

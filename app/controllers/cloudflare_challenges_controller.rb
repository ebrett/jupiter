class CloudflareChallengesController < ApplicationController
  include FeatureFlaggable

  allow_unauthenticated_access

  before_action :check_cloudflare_challenge_feature_flag
  before_action :load_challenge, only: [ :show, :verify, :complete ]
  before_action :check_challenge_validity, only: [ :show, :verify, :complete ]

  def show
    @challenge_data = @challenge.challenge_data
    @site_key = CloudflareConfig.turnstile_site_key
    @callback_url = verify_cloudflare_challenge_url(@challenge.challenge_id)
  end

  def verify
    # Handle browser challenges with manual verification
    if @challenge.challenge_type == "browser_challenge"
      handle_manual_verification
      return
    end

    # Handle Turnstile challenges
    if params[:cf_turnstile_response].blank?
      flash.now[:alert] = "Please complete the challenge"
      render :show
      return
    end

    if verify_turnstile_response(params[:cf_turnstile_response])
      session[:completed_challenge_id] = @challenge.challenge_id
      redirect_to complete_cloudflare_challenge_path(@challenge.challenge_id)
    else
      flash.now[:alert] = "Challenge verification failed. Please try again."
      @challenge_data = @challenge.challenge_data
      @site_key = CloudflareConfig.turnstile_site_key
      @callback_url = verify_cloudflare_challenge_url(@challenge.challenge_id)
      render :show
    end
  end

  def complete
    if session[:completed_challenge_id] != @challenge.challenge_id
      if session[:completed_challenge_id].blank?
        flash[:alert] = "Challenge not completed"
      else
        flash[:alert] = "Challenge mismatch"
      end
      redirect_to sign_in_path
      return
    end

    # Clear the completed challenge from session
    session.delete(:completed_challenge_id)

    # Reconstruct OAuth callback URL with original parameters
    callback_url = "/auth/nationbuilder/callback?#{@challenge.original_params.to_query}&challenge_completed=true"
    redirect_to callback_url
  end

  private

  def check_cloudflare_challenge_feature_flag
    flag = FeatureFlag.find_by(name: "cloudflare_challenge_handling")

    unless flag&.enabled?
      flash[:alert] = "Challenge handling is currently unavailable. Please try signing in again."
      redirect_to sign_in_path
      return false
    end

    # If user is logged in, check if they have access to the feature
    if current_user && !feature_enabled?("cloudflare_challenge_handling")
      flash[:alert] = "Challenge handling is currently unavailable. Please try signing in again."
      redirect_to sign_in_path
      return false
    end

    true
  end

  def load_challenge
    @challenge = CloudflareChallenge.find_by(challenge_id: params[:challenge_id])

    if @challenge.nil?
      flash[:alert] = "Challenge not found"
      redirect_to sign_in_path and return
    end
  end

  def check_challenge_validity
    return unless @challenge

    # For OAuth challenges, we validate using the OAuth state stored in the session
    stored_oauth_state = session[:oauth_state]
    if stored_oauth_state.present? && @challenge.oauth_state != stored_oauth_state
      Rails.logger.error "CloudflareChallenge: OAuth state mismatch - expected: #{stored_oauth_state}, got: #{@challenge.oauth_state}"
      flash[:alert] = "Security validation failed. Please try signing in again."
      redirect_to sign_in_path and return
    end

    if @challenge.expired?
      flash[:alert] = "Challenge has expired. Please try again."
      redirect_to sign_in_path and return
    end
  end

  def verify_turnstile_response(response_token)
    TurnstileVerificationService.new(
      response_token: response_token,
      user_ip: request.remote_ip
    ).verify
  end

  def handle_manual_verification
    # For browser challenges, we assume the user has completed the manual verification
    # by visiting the NationBuilder page. We just need to mark the challenge as completed.

    # Update the challenge timestamp to track manual verification
    @challenge.touch

    # Mark the challenge as completed in the session
    session[:completed_challenge_id] = @challenge.challenge_id

    # Redirect to the completion flow
    redirect_to complete_cloudflare_challenge_path(@challenge.challenge_id)
  end
end

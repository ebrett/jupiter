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

    if @challenge.session_id != session.id.to_s
      flash[:alert] = "Challenge not found"
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
end

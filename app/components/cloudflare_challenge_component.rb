class CloudflareChallengeComponent < ViewComponent::Base
  attr_reader :challenge_data, :site_key, :callback_url

  def initialize(challenge_data:, site_key:, callback_url:)
    @challenge_data = challenge_data
    @site_key = site_key
    @callback_url = callback_url
  end

  def challenge_type
    return "turnstile" if challenge_data["turnstile_present"]
    return "browser_challenge" if challenge_data["challenge_stage_present"]
    return "rate_limit" if challenge_data["rate_limited"]

    "unknown"
  end

  private

  def challenge_title
    case challenge_type
    when "turnstile"
      "Security Check Required"
    when "browser_challenge"
      "Browser Verification Required"
    when "rate_limit"
      "Too Many Requests"
    else
      "Verification Required"
    end
  end

  def challenge_description
    case challenge_type
    when "turnstile"
      "Please complete the security check below to continue with sign-in."
    when "browser_challenge"
      "Your browser verification is in progress. Please refresh the page in a moment."
    when "rate_limit"
      "Too many requests have been made. Please wait a few minutes before trying again."
    else
      "Additional verification required to continue."
    end
  end

  def submit_button_disabled?
    case challenge_type
    when "turnstile", "rate_limit"
      true
    when "browser_challenge"
      false
    else
      true
    end
  end

  def show_turnstile_widget?
    challenge_type == "turnstile" && site_key.present?
  end

  def show_configuration_error?
    challenge_type == "turnstile" && site_key.blank?
  end
end

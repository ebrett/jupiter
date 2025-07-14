class CloudflareChallengeComponent < ViewComponent::Base
  attr_reader :challenge_data, :site_key, :callback_url

  def initialize(challenge_data:, site_key:, callback_url:)
    @challenge_data = challenge_data
    @site_key = site_key
    @callback_url = callback_url
  end

  def challenge_type
    return "turnstile" if challenge_data["turnstile_present"]
    return "browser_challenge" if challenge_data["challenge_stage_present"] || challenge_data["legacy_detection"]
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
      "Please follow the steps below to complete manual verification and continue with sign-in."
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

  def show_manual_verification?
    challenge_type == "browser_challenge"
  end

  def verification_url
    return nil unless show_manual_verification?

    # For Cloudflare challenges, users need to visit the NationBuilder domain
    # to complete the challenge, not the OAuth authorization endpoint
    nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
    return nil if nation_slug.blank?

    # Direct users to the main NationBuilder site to complete Cloudflare challenge
    "https://#{nation_slug}.nationbuilder.com/"
  end
end

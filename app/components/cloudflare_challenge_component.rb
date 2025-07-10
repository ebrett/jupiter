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

    # Build the NationBuilder OAuth URL that user needs to visit manually
    nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
    client_id = ENV["NATIONBUILDER_CLIENT_ID"]
    redirect_uri = ENV["NATIONBUILDER_REDIRECT_URI"]

    return nil if nation_slug.blank? || client_id.blank? || redirect_uri.blank?

    params = {
      response_type: "code",
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: "default"
    }

    "https://#{nation_slug}.nationbuilder.com/oauth/authorize?" + params.to_query
  end
end

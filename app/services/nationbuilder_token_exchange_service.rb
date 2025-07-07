require "net/http"
require "uri"
require "json"

class NationbuilderTokenExchangeService
  class TokenExchangeError < StandardError
    attr_reader :data

    def initialize(message, data: {})
      super(message)
      @data = data
    end
  end

  class CloudflareChallenge
    attr_reader :type, :site_key, :challenge_data

    def initialize(type:, site_key: nil, challenge_data: {})
      @type = type
      @site_key = site_key
      @challenge_data = challenge_data
    end

    def self.from_response(response)
      return nil unless challenge_response?(response)

      if turnstile_challenge?(response.body)
        create_turnstile_challenge(response.body)
      elsif rate_limit_response?(response)
        create_rate_limit_challenge(response.body)
      else
        create_browser_challenge(response.body)
      end
    end

    def to_h
      {
        type: type,
        site_key: site_key,
        challenge_data: challenge_data
      }
    end

    private_class_method def self.challenge_response?(response)
      (response.code == "403" && cloudflare_indicators?(response.body)) ||
        response.code == "429"
    end

    private_class_method def self.cloudflare_indicators?(body)
      body.include?("Just a moment...") ||
        body.include?("cf-challenge-running") ||
        body.include?("cf-turnstile")
    end

    private_class_method def self.turnstile_challenge?(body)
      body.include?("cf-turnstile")
    end

    private_class_method def self.rate_limit_response?(response)
      response.code == "429"
    end

    private_class_method def self.create_turnstile_challenge(body)
      site_key = extract_site_key(body)
      new(
        type: "turnstile",
        site_key: site_key,
        challenge_data: { "turnstile_present" => true }
      )
    end

    private_class_method def self.create_browser_challenge(body)
      data = {}
      data["challenge_stage_present"] = true if body.include?("challenge-stage")
      data["legacy_detection"] = true if body.include?("Just a moment...") && !body.include?("cf-")

      new(
        type: "browser_challenge",
        site_key: nil,
        challenge_data: data
      )
    end

    private_class_method def self.create_rate_limit_challenge(body)
      new(
        type: "rate_limit",
        site_key: nil,
        challenge_data: { "rate_limited" => true }
      )
    end

    private_class_method def self.extract_site_key(body)
      match = body.match(/data-sitekey=["']([^"']+)["']/)
      match ? match[1] : nil
    end
  end

  def initialize(client_id:, client_secret:, redirect_uri:)
    @client_id = client_id
    @client_secret = client_secret
    @redirect_uri = redirect_uri
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
  end

  def exchange_code_for_token(code)
    uri = URI.parse("https://#{@nation_slug}.nationbuilder.com/oauth/token")

    Rails.logger.info "NationBuilder OAuth: Exchanging code for token"
    Rails.logger.info "NationBuilder OAuth: Nation slug: #{@nation_slug}"
    Rails.logger.info "NationBuilder OAuth: Redirect URI: #{@redirect_uri}"

    req = Net::HTTP::Post.new(uri)

    # Set headers that might help bypass Cloudflare challenges
    req["User-Agent"] = "Jupiter OAuth Client/1.0"
    req["Accept"] = "application/json"
    req["Content-Type"] = "application/x-www-form-urlencoded"

    req.set_form_data(
      client_id: @client_id,
      client_secret: @client_secret,
      redirect_uri: @redirect_uri,
      code: code,
      grant_type: "authorization_code"
    )

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    unless res.is_a?(Net::HTTPSuccess)
      Rails.logger.error "NationBuilder OAuth: Token exchange failed"
      Rails.logger.error "NationBuilder OAuth: Response code: #{res.code}"
      Rails.logger.error "NationBuilder OAuth: Response body: #{res.body[0..500]}..." # Truncate for readability

      # Check if this is a Cloudflare challenge
      if cloudflare_challenge = CloudflareChallenge.from_response(res)
        raise TokenExchangeError.new("cloudflare_challenge", data: { challenge: cloudflare_challenge })
      end

      error_data = JSON.parse(res.body) rescue {}
      error_message = error_data["error_description"] || error_data["error"] || "Unknown error"

      raise TokenExchangeError, error_message
    end

    JSON.parse(res.body, symbolize_names: true)
  end
end

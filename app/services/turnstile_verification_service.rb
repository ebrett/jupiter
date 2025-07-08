class TurnstileVerificationService
  API_ENDPOINT = "https://challenges.cloudflare.com/turnstile/v0/siteverify"

  def initialize(response_token:, user_ip:)
    @response_token = response_token
    @user_ip = user_ip
    @secret_key = CloudflareConfig.turnstile_secret_key
  end

  def verify
    return false if response_token.blank? || secret_key.blank?

    response = make_verification_request

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      result["success"] == true
    else
      Rails.logger.error "Turnstile verification failed: #{response.code} #{response.body}"
      false
    end
  rescue => e
    Rails.logger.error "Turnstile verification error: #{e.message}"
    false
  end

  private

  attr_reader :response_token, :user_ip, :secret_key

  def make_verification_request
    uri = URI(API_ENDPOINT)

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = {
      secret: secret_key,
      response: response_token,
      remoteip: user_ip
    }.to_json

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end
  end
end

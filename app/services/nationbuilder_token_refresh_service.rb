require "net/http"
require "uri"
require "json"
require_relative "concerns/circuit_breaker"

class NationbuilderTokenRefreshService
  include CircuitBreaker

  class TokenRefreshError < StandardError; end
  class TokenExpiredError < TokenRefreshError; end
  class InvalidGrantError < TokenRefreshError; end
  class RateLimitError < TokenRefreshError; end

  def initialize(client_id:, client_secret:)
    @client_id = client_id
    @client_secret = client_secret
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
    raise "NATIONBUILDER_NATION_SLUG environment variable is not set" if @nation_slug.nil? || @nation_slug.strip.empty?
  end


  def refresh_token(nationbuilder_token)
    return false if nationbuilder_token.refresh_token.blank?

    start_time = Time.current

    begin
      attempt_refresh(nationbuilder_token)
    rescue TokenRefreshError => e
      log_refresh_failure(nationbuilder_token, e, Time.current - start_time)
      trigger_refresh_failed_hook(nationbuilder_token, e)
      false
    rescue StandardError => e
      log_refresh_failure(nationbuilder_token, e, Time.current - start_time)
      trigger_refresh_failed_hook(nationbuilder_token, e)
      false
    end
  end

  private

  def attempt_refresh(nationbuilder_token)
    max_retries = 3
    retry_count = 0

    begin
      token_data = make_refresh_request(nationbuilder_token.refresh_token)
      update_token_with_response(nationbuilder_token, token_data)
      trigger_refresh_success_hook(nationbuilder_token)
      true
    rescue CircuitBreaker::CircuitOpenError => e
      Rails.logger.error "Circuit breaker open for token refresh: #{e.message}"
      raise TokenRefreshError, "Token refresh service temporarily unavailable"
    rescue TokenRefreshError => e
      retry_count += 1
      if retry_count <= max_retries && should_retry?(e)
        sleep(exponential_backoff_delay(retry_count))
        retry
      else
        raise e
      end
    end
  end

  def make_refresh_request(refresh_token)
    uri = URI.parse("https://#{@nation_slug}.nationbuilder.com/oauth/token")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 30

    req = Net::HTTP::Post.new(uri)
    req.set_form_data(
      client_id: @client_id,
      client_secret: @client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    )

    response = http.request(req)
    handle_refresh_response(response)
  end

  def handle_refresh_response(response)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body, symbolize_names: true)
    when Net::HTTPUnauthorized, Net::HTTPForbidden
      error_data = parse_error_response(response)
      raise_classified_error(error_data, response.code)
    when Net::HTTPBadRequest
      error_data = parse_error_response(response)
      raise_classified_error(error_data, response.code)
    when Net::HTTPTooManyRequests
      retry_after = response["Retry-After"]&.to_i || 60
      raise RateLimitError, "Rate limit exceeded. Retry after #{retry_after} seconds"
    when Net::HTTPServerError
      raise TokenRefreshError, "Server error during token refresh: #{response.code}"
    else
      raise TokenRefreshError, "HTTP error during token refresh: #{response.code} - #{response.body}"
    end
  end

  def parse_error_response(response)
    JSON.parse(response.body, symbolize_names: true)
  rescue JSON::ParserError
    { error: "unknown_error", error_description: response.body }
  end

  def raise_classified_error(error_data, status_code)
    error_type = error_data[:error] || "unknown_error"
    error_description = error_data[:error_description] || error_data[:error] || "Unknown error"

    case error_type
    when "invalid_grant"
      raise InvalidGrantError, "Invalid refresh token: #{error_description}"
    when "expired_token"
      raise TokenExpiredError, "Refresh token expired: #{error_description}"
    when "invalid_client"
      raise TokenRefreshError, "Invalid client credentials: #{error_description}"
    else
      raise TokenRefreshError, "Token refresh failed (#{status_code}): #{error_description}"
    end
  end

  def update_token_with_response(nationbuilder_token, token_data)
    nationbuilder_token.update_tokens!(
      access_token: token_data[:access_token],
      refresh_token: token_data[:refresh_token] || nationbuilder_token.refresh_token, # Keep existing if not provided
      expires_in: token_data[:expires_in],
      scope: token_data[:scope] || nationbuilder_token.scope,
      raw_response: token_data
    )
  end

  def should_retry?(error)
    case error
    when Net::HTTPServerError, Net::ReadTimeout, Net::OpenTimeout
      true
    when RateLimitError
      true
    when TokenRefreshError
      # Don't retry on authentication/authorization errors
      !error.message.match?(/401|403|invalid_grant|expired_token|invalid_client/)
    else
      false
    end
  end

  def exponential_backoff_delay(retry_count)
    # Base delay of 1 second, exponentially increasing with jitter
    base_delay = 1.0
    max_delay = 16.0
    delay = [ base_delay * (2 ** (retry_count - 1)), max_delay ].min

    # Add jitter to prevent thundering herd
    jitter = rand(0.1..0.3)
    delay * (1 + jitter)
  end

  def trigger_refresh_success_hook(nationbuilder_token)
    Rails.logger.info "Token refresh successful for user #{nationbuilder_token.user_id}"

    # Audit log the success
    if defined?(NationbuilderAuditLogger)
      audit_logger = NationbuilderAuditLogger.new
      audit_logger.log_token_event(:token_refreshed,
        user: nationbuilder_token.user,
        details: {
          token_id: nationbuilder_token.id,
          expires_at: nationbuilder_token.expires_at
        }
      )
    end
  end

  def trigger_refresh_failed_hook(nationbuilder_token, error)
    Rails.logger.error "Token refresh failed for user #{nationbuilder_token.user_id}: #{error.message}"

    # Audit log the failure
    if defined?(NationbuilderAuditLogger)
      audit_logger = NationbuilderAuditLogger.new
      audit_logger.log_token_event(:token_refresh_failed,
        user: nationbuilder_token.user,
        details: {
          token_id: nationbuilder_token.id,
          error: error.class.name,
          error_message: error.message
        }
      )
    end
  end

  def log_refresh_failure(nationbuilder_token, error, duration)
    Rails.logger.error "Token refresh failed for user #{nationbuilder_token.user_id} after #{duration.round(2)}s: #{error.class.name} - #{error.message}"
  end

  # Fallback method when circuit is open
  def handle_circuit_open(refresh_token)
    Rails.logger.error "Circuit breaker is open for token refresh service"
    raise TokenRefreshError, "Token refresh service is temporarily unavailable due to repeated failures"
  end

  # Circuit breaker configuration - must be after method definitions
  circuit_breaker :make_refresh_request,
    failure_threshold: 3,
    timeout: 30.seconds,
    fallback: :handle_circuit_open
end

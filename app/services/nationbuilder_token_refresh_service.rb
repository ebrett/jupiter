require "net/http"
require "uri"
require "json"

class NationbuilderTokenRefreshService
  class TokenRefreshError < StandardError; end

  def initialize(client_id:, client_secret:)
    @client_id = client_id
    @client_secret = client_secret
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
    raise "NATIONBUILDER_NATION_SLUG environment variable is not set" if @nation_slug.nil? || @nation_slug.strip.empty?
  end

  def refresh_token(nationbuilder_token)
    return false if nationbuilder_token.refresh_token.blank?

    attempt_refresh(nationbuilder_token)
  rescue TokenRefreshError => e
    Rails.logger.error "Token refresh failed for user #{nationbuilder_token.user_id}: #{e.message}"
    trigger_refresh_failed_hook(nationbuilder_token, e)
    false
  rescue StandardError => e
    Rails.logger.error "Unexpected error during token refresh for user #{nationbuilder_token.user_id}: #{e.message}"
    trigger_refresh_failed_hook(nationbuilder_token, e)
    false
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
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(
      client_id: @client_id,
      client_secret: @client_secret,
      refresh_token: refresh_token,
      grant_type: "refresh_token"
    )

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    handle_refresh_response(res)
  end

  def handle_refresh_response(response)
    case response
    when Net::HTTPSuccess
      JSON.parse(response.body, symbolize_names: true)
    when Net::HTTPUnauthorized, Net::HTTPForbidden
      raise TokenRefreshError, "Invalid refresh token: #{response.code} - #{response.body}"
    when Net::HTTPBadRequest
      error_data = JSON.parse(response.body) rescue {}
      error_description = error_data["error_description"] || error_data["error"] || "Bad request"
      raise TokenRefreshError, "Token refresh failed: #{error_description}"
    else
      raise TokenRefreshError, "HTTP error during token refresh: #{response.code} - #{response.body}"
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
    # Retry on network errors, server errors, but not on auth errors
    error.message.include?("HTTP error") && 
      !error.message.include?("401") && 
      !error.message.include?("403")
  end

  def exponential_backoff_delay(retry_count)
    # Base delay of 1 second, exponentially increasing with jitter
    base_delay = 1.0
    max_delay = 16.0
    delay = [base_delay * (2 ** (retry_count - 1)), max_delay].min
    
    # Add jitter to prevent thundering herd
    jitter = rand(0.1..0.3)
    delay * (1 + jitter)
  end

  def trigger_refresh_success_hook(nationbuilder_token)
    Rails.logger.info "Token refresh successful for user #{nationbuilder_token.user_id}"
    
    # Future: Add event system or webhook notifications here
    # Example: EventBus.publish(:token_refreshed, { user_id: nationbuilder_token.user_id })
  end

  def trigger_refresh_failed_hook(nationbuilder_token, error)
    Rails.logger.error "Token refresh failed for user #{nationbuilder_token.user_id}: #{error.message}"
    
    # Future: Add event system, notifications, or admin alerts here
    # Example: EventBus.publish(:token_refresh_failed, { user_id: nationbuilder_token.user_id, error: error.message })
  end
end
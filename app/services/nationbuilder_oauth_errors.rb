require "cgi"
require "timeout"

module NationbuilderOauthErrors
  # Base error class for all Nationbuilder OAuth2-related errors
  class OAuthError < StandardError
    attr_reader :error_code, :error_description, :http_status, :raw_response

    def initialize(message, error_code: nil, error_description: nil, http_status: nil, raw_response: nil)
      super(message)
      @error_code = error_code
      @error_description = error_description
      @http_status = http_status
      @raw_response = raw_response
    end

    def to_h
      {
        message: message,
        error_code: error_code,
        error_description: error_description,
        http_status: http_status,
        error_type: self.class.name
      }
    end

    def loggable_details
      details = to_h
      details[:raw_response] = raw_response if raw_response
      details
    end
  end

  # Token-related errors
  class TokenError < OAuthError; end

  # Refresh token is invalid, expired, or revoked
  class InvalidRefreshTokenError < TokenError
    def initialize(message = "Refresh token is invalid or expired", **kwargs)
      super(message, **kwargs)
    end

    def requires_reauthentication?
      true
    end
  end

  # Access token is invalid or expired
  class InvalidAccessTokenError < TokenError
    def initialize(message = "Access token is invalid or expired", **kwargs)
      super(message, **kwargs)
    end

    def can_retry_with_refresh?
      true
    end
  end

  # Token exchange failed during initial authorization
  class TokenExchangeError < TokenError
    def initialize(message = "Failed to exchange authorization code for tokens", **kwargs)
      super(message, **kwargs)
    end
  end

  # Token refresh failed
  class TokenRefreshError < TokenError
    def initialize(message = "Failed to refresh access token", **kwargs)
      super(message, **kwargs)
    end
  end

  # User-related authorization errors
  class AuthorizationError < OAuthError; end

  # User denied authorization or access was revoked
  class AccessRevokedError < AuthorizationError
    def initialize(message = "User has revoked access or denied authorization", **kwargs)
      super(message, **kwargs)
    end

    def requires_reauthentication?
      true
    end

    def user_action_required?
      true
    end
  end

  # User's account or application access has been disabled
  class AccountDisabledError < AuthorizationError
    def initialize(message = "User account or application access has been disabled", **kwargs)
      super(message, **kwargs)
    end

    def requires_admin_intervention?
      true
    end
  end

  # API-related errors
  class ApiError < OAuthError; end

  # Rate limiting or quota exceeded
  class RateLimitError < ApiError
    attr_reader :retry_after, :reset_time

    def initialize(message = "API rate limit exceeded", retry_after: nil, reset_time: nil, **kwargs)
      super(message, **kwargs)
      @retry_after = retry_after
      @reset_time = reset_time
    end

    def can_retry?
      true
    end

    def retry_delay
      retry_after || 60 # Default to 60 seconds if not specified
    end
  end

  # Network or HTTP-related errors
  class NetworkError < OAuthError
    def initialize(message = "Network error occurred during OAuth request", **kwargs)
      super(message, **kwargs)
    end

    def can_retry?
      true
    end
  end

  # Server errors (5xx responses)
  class ServerError < OAuthError
    def initialize(message = "Server error occurred", **kwargs)
      super(message, **kwargs)
    end

    def can_retry?
      true
    end
  end

  # Client configuration errors
  class ConfigurationError < OAuthError
    def initialize(message = "OAuth configuration error", **kwargs)
      super(message, **kwargs)
    end

    def requires_admin_intervention?
      true
    end
  end

  # Invalid scope or permissions
  class ScopeError < OAuthError
    def initialize(message = "Invalid or insufficient OAuth scope", **kwargs)
      super(message, **kwargs)
    end

    def requires_reauthentication?
      true
    end
  end

  # Generic authentication failure
  class AuthenticationError < OAuthError
    def initialize(message = "Authentication failed", **kwargs)
      super(message, **kwargs)
    end
  end

  # Error classification and handling utilities
  class ErrorClassifier
    # Map HTTP status codes to appropriate error classes
    HTTP_STATUS_MAPPING = {
      400 => TokenError,
      401 => InvalidAccessTokenError,
      403 => AccessRevokedError,
      429 => RateLimitError,
      500..599 => ServerError
    }.freeze

    # Map OAuth2 error codes to specific error classes
    OAUTH_ERROR_MAPPING = {
      "invalid_request" => TokenError,
      "invalid_client" => ConfigurationError,
      "invalid_grant" => InvalidRefreshTokenError,
      "unauthorized_client" => ConfigurationError,
      "unsupported_grant_type" => ConfigurationError,
      "invalid_scope" => ScopeError,
      "access_denied" => AccessRevokedError,
      "invalid_token" => InvalidAccessTokenError,
      "expired_token" => InvalidAccessTokenError,
      "revoked_token" => AccessRevokedError,
      "insufficient_scope" => ScopeError
    }.freeze

    def self.classify_http_error(status_code, response_body = nil, headers = {})
      error_class = HTTP_STATUS_MAPPING.find { |k, v| k === status_code }&.last || OAuthError

      # Try to parse OAuth error from response
      oauth_error = parse_oauth_error(response_body) if response_body
      if oauth_error && OAUTH_ERROR_MAPPING[oauth_error[:error]]
        error_class = OAUTH_ERROR_MAPPING[oauth_error[:error]]
      end

      # Handle rate limiting
      if status_code == 429
        retry_after = headers["retry-after"]&.to_i
        reset_time = headers["x-ratelimit-reset"]&.to_i
        return RateLimitError.new(
          "Rate limit exceeded",
          http_status: status_code,
          retry_after: retry_after,
          reset_time: reset_time ? Time.at(reset_time) : nil,
          raw_response: response_body
        )
      end

      error_class.new(
        oauth_error&.dig(:error_description) || "HTTP #{status_code} error",
        error_code: oauth_error&.dig(:error),
        error_description: oauth_error&.dig(:error_description),
        http_status: status_code,
        raw_response: response_body
      )
    end

    def self.classify_network_error(exception)
      case exception
      when Net::OpenTimeout, Net::ReadTimeout
        NetworkError.new("Request timeout: #{exception.message}")
      when Timeout::Error
        NetworkError.new("Request timeout: #{exception.message}")
      when SocketError, Errno::ECONNREFUSED
        NetworkError.new("Connection error: #{exception.message}")
      when Net::HTTPError
        NetworkError.new("HTTP error: #{exception.message}")
      else
        NetworkError.new("Network error: #{exception.message}")
      end
    end

    private

    def self.parse_oauth_error(response_body)
      return nil unless response_body

      JSON.parse(response_body).symbolize_keys
    rescue JSON::ParserError
      # Try to parse URL-encoded response
      begin
        CGI.parse(response_body).transform_values(&:first).symbolize_keys
      rescue => e
        Rails.logger.debug "Failed to parse OAuth error response: #{e.message}"
        nil
      end
    end
  end

  # Error recovery strategies
  class RecoveryStrategy
    def self.for_error(error)
      case error
      when InvalidRefreshTokenError, AccessRevokedError
        :reauthenticate
      when InvalidAccessTokenError
        :refresh_token
      when RateLimitError
        :wait_and_retry
      when NetworkError, ServerError
        :retry_with_backoff
      when ConfigurationError, ScopeError
        :admin_intervention
      else
        :log_and_fail
      end
    end

    def self.should_retry?(error, attempt_count = 1, max_retries = 3)
      return false if attempt_count >= max_retries

      case for_error(error)
      when :refresh_token, :wait_and_retry, :retry_with_backoff
        true
      else
        false
      end
    end

    def self.retry_delay(error, attempt_count = 1)
      case error
      when RateLimitError
        error.retry_delay
      when NetworkError, ServerError
        # Exponential backoff: 2^attempt seconds with jitter
        base_delay = 2 ** attempt_count
        jitter = rand(0.5..1.5)
        [ base_delay * jitter, 300 ].min # Cap at 5 minutes
      else
        0
      end
    end
  end
end

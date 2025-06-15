require "net/http"
require "uri"
require "json"
require_relative "nationbuilder_oauth_errors"
require_relative "nationbuilder_error_handler"

class NationbuilderApiClient
  include NationbuilderOauthErrors

  # Legacy error classes for backward compatibility
  class ApiError < OAuthError; end
  class AuthenticationError < ApiError; end
  class TokenRefreshError < ApiError; end

  # Connection pool configuration
  CONNECTION_POOL_SIZE = 10
  CONNECTION_TIMEOUT = 5
  KEEP_ALIVE_TIMEOUT = 30
  READ_TIMEOUT = 30

  def initialize(user:)
    @user = user
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
    @error_handler = NationbuilderErrorHandler.new(user: user)
    @audit_logger = NationbuilderAuditLogger.new
    @current_token = nil
    @token_cache_expires_at = nil
    @refresh_mutex = Mutex.new

    raise ConfigurationError, "NATIONBUILDER_NATION_SLUG environment variable is not set" if @nation_slug.nil? || @nation_slug.strip.empty?
    raise ArgumentError, "User must have a nationbuilder_token" unless current_token
  end

  # Main API request method
  def request(method:, path:, params: {}, headers: {}, retry_on_auth_failure: true, attempt_count: 1)
    start_time = Time.current
    correlation_id = generate_correlation_id

    log_request(method, path, params, correlation_id)

    # Log API request start
    @audit_logger.log_api_event(:api_request_started,
      user: @user,
      endpoint: path,
      details: {
        method: method,
        attempt_count: attempt_count,
        correlation_id: correlation_id
      }
    )

    begin
      # Check if token needs refresh before making request
      ensure_valid_token!

      response = make_authenticated_request(method: method, path: path, params: params, headers: headers)

      duration = ((Time.current - start_time) * 1000).round(2)

      log_response(response)

      # Log successful API request
      @audit_logger.log_api_event(:api_request_completed,
        user: @user,
        endpoint: path,
        details: {
          method: method,
          status: response.code.to_i,
          duration: duration,
          correlation_id: correlation_id
        }
      )

      # Log performance metrics
      @audit_logger.log_performance_metrics(:api_request, duration, {
        endpoint: path,
        method: method,
        status: response.code.to_i,
        correlation_id: correlation_id
      })

      handle_response(response)
    rescue StandardError => e
      duration = ((Time.current - start_time) * 1000).round(2)

      # Log failed API request
      @audit_logger.log_api_event(:api_request_failed,
        user: @user,
        endpoint: path,
        details: {
          method: method,
          error: e.class.name,
          duration: duration,
          attempt_count: attempt_count,
          correlation_id: correlation_id
        }
      )

      # Convert network errors first
      if [ Net::OpenTimeout, Net::ReadTimeout, Timeout::Error ].include?(e.class)
        raise ErrorClassifier.classify_network_error(e)
      end

      handle_request_error(e, method: method, path: path, params: params, headers: headers,
                          retry_on_auth_failure: retry_on_auth_failure, attempt_count: attempt_count,
                          correlation_id: correlation_id)
    end
  end

  # Convenience methods for common HTTP verbs
  def get(path, params: {}, headers: {})
    request(method: :get, path: path, params: params, headers: headers)
  end

  def post(path, params: {}, headers: {})
    request(method: :post, path: path, params: params, headers: headers)
  end

  def put(path, params: {}, headers: {})
    request(method: :put, path: path, params: params, headers: headers)
  end

  def delete(path, params: {}, headers: {})
    request(method: :delete, path: path, params: params, headers: headers)
  end

  # Cached API requests for frequently accessed data
  def get_with_cache(path, params: {}, cache_options: {})
    cache_key = "nationbuilder:#{@user.id}:#{path}:#{params.to_json}"
    expires_in = cache_options[:expires_in] || 5.minutes

    Rails.cache.fetch(cache_key, expires_in: expires_in) do
      get(path, params: params)
    end
  end

  private

  def current_token(reload: false)
    # Use cached token if available and not expired
    if !reload && @current_token && @token_cache_expires_at && @token_cache_expires_at > Time.current
      return @current_token
    end

    # Reload from database
    @current_token = @user.reload.nationbuilder_tokens.order(created_at: :desc).first
    @token_cache_expires_at = 30.seconds.from_now
    @current_token
  end

  def ensure_valid_token!
    token = current_token

    if token.needs_refresh?
      Rails.logger.info "Token needs refresh for user #{@user.id}, attempting refresh"
      refresh_token_with_lock
    end
  end

  def refresh_token_with_lock
    lock_key = "nationbuilder_token_refresh:#{@user.id}"

    # Use database advisory lock for distributed locking
    if ActiveRecord::Base.connection.respond_to?(:with_advisory_lock)
      begin
        ActiveRecord::Base.connection.with_advisory_lock(lock_key, timeout_seconds: 30) do
          perform_token_refresh
        end
      rescue => e
        # Handle any advisory lock errors
        Rails.logger.error "Failed to acquire lock for token refresh: #{e.message}"
        # Check if another process already refreshed the token
        token = current_token(reload: true)
        unless token.needs_refresh?
          Rails.logger.info "Token was refreshed by another process"
          return
        end
        raise TokenRefreshError, "Unable to acquire lock for token refresh"
      end
    else
      # Fallback to mutex for test environment or databases without advisory locks
      @refresh_mutex ||= Mutex.new
      @refresh_mutex.synchronize { perform_token_refresh }
    end
  end

  def perform_token_refresh
    # Double-check if token still needs refresh after acquiring lock
    token = current_token(reload: true)
    return unless token.needs_refresh?

    begin
      success = token.refresh!

      unless success
        Rails.logger.error "Failed to refresh token for user #{@user.id}"
        raise TokenRefreshError, "Unable to refresh access token"
      end

      # Clear cached token after refresh
      @current_token = nil
      @token_cache_expires_at = nil

      Rails.logger.info "Token refresh successful for user #{@user.id}"
    rescue => e
      Rails.logger.error "Token refresh failed for user #{@user.id}: #{e.message}"
      raise
    end
  end

  def make_authenticated_request(method:, path:, params:, headers:)
    token = current_token(reload: true)

    raise AuthenticationError, "No valid access token available" unless token.valid_for_api_use?

    uri = build_uri(path)
    request = build_http_request(method: method, uri: uri, params: params, headers: headers)
    request["Authorization"] = "Bearer #{token.access_token}"

    # Use persistent HTTP connection from pool
    response = nil
    http_connection_for(uri) do |http|
      response = http.request(request)
    end

    response
  end

  def http_connection_for(uri)
    # Simple connection pooling using thread-local storage
    thread_key = "nationbuilder_http_#{uri.host}:#{uri.port}"
    http = Thread.current[thread_key]

    if http.nil? || !http.started?
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.keep_alive_timeout = KEEP_ALIVE_TIMEOUT
      http.open_timeout = CONNECTION_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      http.start
      Thread.current[thread_key] = http
    end

    yield http
  rescue => e
    # Close connection on error and remove from thread storage
    http&.finish rescue nil
    Thread.current[thread_key] = nil
    raise e
  end

  def build_uri(path)
    base_url = "https://#{@nation_slug}.nationbuilder.com"
    # Ensure path starts with /
    path = "/#{path}" unless path.start_with?("/")
    URI.parse("#{base_url}#{path}")
  end

  def build_http_request(method:, uri:, params:, headers:)
    case method.to_sym
    when :get
      uri.query = URI.encode_www_form(params) if params.any?
      Net::HTTP::Get.new(uri)
    when :post
      request = Net::HTTP::Post.new(uri)
      set_request_body(request, params, headers)
      request
    when :put
      request = Net::HTTP::Put.new(uri)
      set_request_body(request, params, headers)
      request
    when :delete
      uri.query = URI.encode_www_form(params) if params.any?
      Net::HTTP::Delete.new(uri)
    else
      raise ArgumentError, "Unsupported HTTP method: #{method}"
    end.tap do |req|
      headers.each { |key, value| req[key] = value }
      req["Content-Type"] ||= "application/json" if [ :post, :put ].include?(method.to_sym)
    end
  end

  def set_request_body(request, params, headers)
    if headers["Content-Type"]&.include?("application/json") || headers.empty?
      request.body = params.to_json if params.any?
    else
      request.set_form_data(params) if params.any?
    end
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      parse_response_body(response)
    when Net::HTTPUnauthorized, Net::HTTPForbidden, Net::HTTPClientError, Net::HTTPServerError
      # Use the new error classification system
      error = ErrorClassifier.classify_http_error(
        response.code.to_i,
        response.body,
        response.to_hash
      )
      raise error
    else
      raise ApiError, "Unexpected response (#{response.code}): #{response.body}"
    end
  end

  def parse_response_body(response)
    return nil if response.body.nil? || response.body.strip.empty?

    content_type = response["Content-Type"]
    if content_type&.include?("application/json")
      JSON.parse(response.body, symbolize_names: true)
    else
      response.body
    end
  rescue JSON::ParserError => e
    Rails.logger.warn "Failed to parse JSON response: #{e.message}"
    response.body
  end

  def handle_request_error(error, method:, path:, params:, headers:, retry_on_auth_failure:, attempt_count:, correlation_id: nil)
    context = {
      method: method,
      path: path,
      attempt_count: attempt_count,
      retry_on_auth_failure: retry_on_auth_failure,
      correlation_id: correlation_id
    }

    # Only convert to OAuth errors for actual errors we want to handle
    oauth_error = if error.is_a?(OAuthError)
      error
    elsif error.is_a?(StandardError)
      ErrorClassifier.classify_network_error(error)
    else
      error
    end

    # Only use error handler for errors that should be handled
    if should_use_error_handler?(oauth_error)
      recovery_result = @error_handler.handle_error(oauth_error, context: context)

      # Decide whether to retry based on the recovery strategy
      case recovery_result[:strategy]
      when :token_refresh
        if recovery_result[:success] && retry_on_auth_failure
          # Retry the request with refreshed token
          return request(method: method, path: path, params: params, headers: headers,
                        retry_on_auth_failure: false, attempt_count: attempt_count + 1)
        end
      when :wait_and_retry, :retry_with_backoff
        if recovery_result[:can_retry] && retry_on_auth_failure && attempt_count < 3
          sleep(recovery_result[:retry_delay]) if recovery_result[:retry_delay]
          return request(method: method, path: path, params: params, headers: headers,
                        retry_on_auth_failure: retry_on_auth_failure, attempt_count: attempt_count + 1)
        end
      end
    end

    # If we can't recover or shouldn't retry, re-raise the original error
    raise error
  end

  def should_use_error_handler?(error)
    # Only use error handler for OAuth-related errors
    error.is_a?(OAuthError) ||
    error.is_a?(NationbuilderOauthErrors::NetworkError) ||
    error.message.downcase.include?("oauth") ||
    error.message.downcase.include?("token")
  end

  def log_request(method, path, params, correlation_id = nil)
    Rails.logger.debug "NationBuilder API Request [#{correlation_id}]: #{method.upcase} #{path} with params: #{params.inspect}"
  end

  def log_response(response, correlation_id = nil)
    Rails.logger.debug "NationBuilder API Response [#{correlation_id}]: #{response.code} - #{response.body&.truncate(500)}"
  end

  def generate_correlation_id
    "api_#{SecureRandom.hex(6)}"
  end

  # Class method to clean up connections at the end of requests
  def self.cleanup_connections
    Thread.current.keys.select { |k| k.to_s.start_with?("nationbuilder_http_") }.each do |key|
      http = Thread.current[key]
      http&.finish rescue nil
      Thread.current[key] = nil
    end
  end
end

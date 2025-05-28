require "net/http"
require "uri"
require "json"

class NationbuilderApiClient
  class ApiError < StandardError; end
  class AuthenticationError < ApiError; end
  class TokenRefreshError < ApiError; end

  def initialize(user:)
    @user = user
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
    @refresh_mutex = Mutex.new
    @pending_requests = Queue.new
    @refreshing = false
    
    raise "NATIONBUILDER_NATION_SLUG environment variable is not set" if @nation_slug.nil? || @nation_slug.strip.empty?
    raise ArgumentError, "User must have a nationbuilder_token" unless current_token
  end

  # Main API request method
  def request(method:, path:, params: {}, headers: {}, retry_on_auth_failure: true)
    log_request(method, path, params)
    
    # If a refresh is in progress, wait for it to complete
    wait_for_refresh_if_needed
    
    # Check if token needs refresh before making request
    ensure_valid_token!
    
    response = make_authenticated_request(method: method, path: path, params: params, headers: headers)
    
    log_response(response)
    handle_response(response)
  rescue AuthenticationError => e
    if retry_on_auth_failure
      Rails.logger.warn "Authentication failed, attempting token refresh: #{e.message}"
      refresh_token_and_retry(method: method, path: path, params: params, headers: headers)
    else
      raise e
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

  private

  def current_token(reload: false)
    if reload
      @user.reload.nationbuilder_tokens.order(created_at: :desc).first
    else
      @user.nationbuilder_tokens.order(created_at: :desc).first
    end
  end

  def ensure_valid_token!
    token = current_token
    
    if token.needs_refresh?
      Rails.logger.info "Token needs refresh for user #{@user.id}, attempting refresh"
      refresh_token_if_needed
    end
  end

  def refresh_token_if_needed
    @refresh_mutex.synchronize do
      # Double-check if token still needs refresh (another thread might have refreshed it)
      token = current_token(reload: true)
      return unless token.needs_refresh?
      
      # Mark that we're refreshing to queue subsequent requests
      @refreshing = true
      
      begin
        success = token.refresh!
        
        unless success
          Rails.logger.error "Failed to refresh token for user #{@user.id}"
          raise TokenRefreshError, "Unable to refresh access token"
        end
        
        Rails.logger.info "Token refresh successful for user #{@user.id}"
      ensure
        @refreshing = false
      end
    end
  end

  def make_authenticated_request(method:, path:, params:, headers:)
    token = current_token(reload: true)
    
    raise AuthenticationError, "No valid access token available" unless token.valid_for_api_use?
    
    uri = build_uri(path)
    request = build_http_request(method: method, uri: uri, params: params, headers: headers)
    request["Authorization"] = "Bearer #{token.access_token}"
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.request(request)
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
      req["Content-Type"] ||= "application/json" if [:post, :put].include?(method.to_sym)
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
    when Net::HTTPUnauthorized, Net::HTTPForbidden
      raise AuthenticationError, "API request failed with #{response.code}: #{response.body}"
    when Net::HTTPClientError
      raise ApiError, "Client error (#{response.code}): #{response.body}"
    when Net::HTTPServerError
      raise ApiError, "Server error (#{response.code}): #{response.body}"
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

  def refresh_token_and_retry(method:, path:, params:, headers:)
    refresh_token_if_needed
    # Retry the request without auth failure retry to prevent infinite loops
    request(method: method, path: path, params: params, headers: headers, retry_on_auth_failure: false)
  end

  def wait_for_refresh_if_needed
    # If a refresh is currently in progress, wait for it to complete
    if @refreshing
      Rails.logger.debug "Waiting for token refresh to complete for user #{@user.id}"
      
      # Simple polling with exponential backoff
      wait_time = 0.1
      max_wait = 30 # seconds
      total_waited = 0
      
      while @refreshing && total_waited < max_wait
        sleep(wait_time)
        total_waited += wait_time
        wait_time = [wait_time * 1.5, 2.0].min # Cap at 2 seconds
      end
      
      if @refreshing
        Rails.logger.warn "Token refresh taking too long for user #{@user.id}, proceeding anyway"
      end
    end
  end

  def log_request(method, path, params)
    Rails.logger.debug "NationBuilder API Request: #{method.upcase} #{path} with params: #{params.inspect}"
  end

  def log_response(response)
    Rails.logger.debug "NationBuilder API Response: #{response.code} - #{response.body&.truncate(500)}"
  end
end
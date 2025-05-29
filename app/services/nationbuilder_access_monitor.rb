require_relative "nationbuilder_oauth_errors"

class NationbuilderAccessMonitor
  include NationbuilderOauthErrors

  attr_reader :user, :logger

  def initialize(user:, logger: Rails.logger)
    @user = user
    @logger = logger
    @nation_slug = ENV["NATIONBUILDER_NATION_SLUG"]
  end

  # Check if user's access has been revoked
  def access_revoked?
    token = current_token
    return true unless token # No token means no access

    begin
      # Try a minimal API call to check if access is still valid
      test_access_validity(token)
      false
    rescue AccessRevokedError
      handle_access_revocation
      true
    rescue InvalidAccessTokenError
      # Token might be expired, try refresh
      if token.refresh!
        false # Refresh succeeded, access is still valid
      else
        handle_access_revocation
        true
      end
    rescue => e
      logger.warn "Unable to verify access status for user #{user.id}: #{e.message}"
      false # Assume access is valid if we can't verify
    end
  end

  # Detect revocation from an API error response
  def detect_revocation_from_error(error)
    revocation_indicators = [
      # HTTP status codes that indicate revocation
      error.try(:http_status) == 403,

      # OAuth error codes that indicate revocation
      %w[access_denied revoked_token invalid_grant].include?(error.try(:error_code)),

      # Error messages that indicate revocation
      error.message&.downcase&.include?("revoked"),
      error.message&.downcase&.include?("access denied"),
      error.try(:error_description)&.downcase&.include?("revoked"),

      # Specific error types
      error.is_a?(AccessRevokedError),

      # Refresh token failures that suggest revocation rather than expiration
      (error.is_a?(InvalidRefreshTokenError) &&
       (error.http_status == 403 || error.error_code == "invalid_grant"))
    ]

    revocation_indicators.any?
  end

  # Monitor access status for a user (can be called periodically)
  def monitor_access_status
    return unless should_monitor_user?

    token = current_token
    return log_monitoring_event(:no_token) unless token

    # Skip monitoring if token was recently checked
    return if recently_verified?(token)

    begin
      if access_revoked?
        log_monitoring_event(:access_revoked, token_id: token.id)
        handle_access_revocation
      else
        log_monitoring_event(:access_verified, token_id: token.id)
        mark_token_verified(token)
      end
    rescue => e
      log_monitoring_event(:monitoring_error, error: e.message, token_id: token.id)
    end
  end

  # Check if revocation affects multiple tokens (user revoked app access entirely)
  def global_revocation_detected?
    # If we have multiple tokens for the user and they're all failing,
    # it's likely a global revocation
    tokens = user.nationbuilder_tokens.where("expires_at > ?", 1.hour.ago)
    return false if tokens.count < 2

    failed_tokens = tokens.select do |token|
      begin
        test_access_validity(token)
        false
      rescue AccessRevokedError, InvalidRefreshTokenError
        true
      rescue
        false
      end
    end

    # If more than 80% of recent tokens are failing, consider it global revocation
    failed_tokens.count.to_f / tokens.count > 0.8
  end

  # Handle access revocation cleanup
  def handle_access_revocation
    log_monitoring_event(:handling_revocation, user_id: user.id)

    # Mark all user tokens as revoked/expired
    revoke_all_user_tokens

    # Create audit log entry
    create_revocation_audit_log

    # Notify relevant systems
    notify_revocation_detected

    true
  end

  # Revoke all tokens for the user
  def revoke_all_user_tokens
    updated_count = user.nationbuilder_tokens.where("expires_at > ?", Time.current).update_all(
      expires_at: Time.current,
      updated_at: Time.current
    )

    log_monitoring_event(:tokens_revoked,
      user_id: user.id,
      tokens_affected: updated_count
    )

    updated_count
  end

  # Create an audit log entry for the revocation
  def create_revocation_audit_log
    audit_data = {
      event: "access_revocation_detected",
      user_id: user.id,
      timestamp: Time.current,
      detection_method: "api_error_analysis",
      affected_tokens: user.nationbuilder_tokens.count,
      metadata: {
        nation_slug: @nation_slug,
        user_email: user.email_address
      }
    }

    logger.warn "Access revocation audit: #{audit_data.to_json}"

    # Future: Store in dedicated audit table
    audit_data
  end

  # Get revocation status summary for user
  def revocation_status_summary
    token = current_token

    {
      user_id: user.id,
      has_active_tokens: token&.valid_for_api_use? || false,
      total_tokens: user.nationbuilder_tokens.count,
      active_tokens: user.nationbuilder_tokens.where("expires_at > ?", Time.current).count,
      last_successful_api_call: get_last_successful_api_call,
      access_status: determine_access_status,
      last_verified_at: get_last_verification_time(token),
      needs_reauthentication: !token&.valid_for_api_use?
    }
  end

  # Test if a specific error indicates permanent revocation vs temporary issues
  def permanent_revocation?(error)
    case error
    when AccessRevokedError
      true
    when InvalidRefreshTokenError
      # Check if it's due to revocation vs expiration
      error.http_status == 403 ||
      error.error_code == "access_denied" ||
      error.error_description&.include?("revoked")
    else
      false
    end
  end

  private

  def current_token
    user.nationbuilder_tokens.order(created_at: :desc).first
  end

  def should_monitor_user?
    # Only monitor users who have tokens and have been active recently
    return false unless user.nationbuilder_tokens.any?

    # Add logic for determining which users to monitor
    # For example: recently active users, VIP users, etc.
    true
  end

  def recently_verified?(token)
    # Check if we've verified this token in the last hour
    # This would typically be stored in cache or database
    # For now, we'll just return false to always verify
    false
  end

  def mark_token_verified(token)
    # Mark token as recently verified
    # This would typically update cache or database
    log_monitoring_event(:token_verified, token_id: token.id)
  end

  def test_access_validity(token)
    # Make a minimal API call to test if the token is still valid
    # Use a lightweight endpoint like getting the current user info
    uri = URI.parse("https://#{@nation_slug}.nationbuilder.com/api/v1/people/me")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{token.access_token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    case response
    when Net::HTTPSuccess
      true
    when Net::HTTPUnauthorized
      if response.body&.include?("revoked") || response.body&.include?("access_denied")
        raise AccessRevokedError.new("Token access revoked",
          http_status: response.code.to_i,
          raw_response: response.body
        )
      else
        raise InvalidAccessTokenError.new("Token invalid or expired",
          http_status: response.code.to_i,
          raw_response: response.body
        )
      end
    when Net::HTTPForbidden
      raise AccessRevokedError.new("Access forbidden - likely revoked",
        http_status: response.code.to_i,
        raw_response: response.body
      )
    else
      # Other errors don't necessarily indicate revocation
      raise NetworkError.new("API test call failed: #{response.code}")
    end
  end

  def notify_revocation_detected
    # Notify relevant systems about the revocation
    # This could trigger:
    # - User notifications
    # - Admin alerts
    # - Cleanup jobs
    # - Analytics events

    log_monitoring_event(:revocation_notifications_sent, user_id: user.id)

    # Future integrations:
    # - Send email to user
    # - Create admin dashboard alert
    # - Trigger cleanup background job
    # - Update analytics/metrics
  end

  def determine_access_status
    token = current_token
    return :no_tokens unless token
    return :expired if token.expired?
    return :active if token.valid_for_api_use?
    return :needs_refresh if token.refresh_token.present?
    :unknown
  end

  def get_last_successful_api_call
    # This would typically be stored in a separate table tracking API calls
    # For now, return a placeholder
    nil
  end

  def get_last_verification_time(token)
    # This would typically be stored in cache or database
    # For now, return nil
    nil
  end

  def log_monitoring_event(event, **details)
    log_data = {
      event: "access_monitoring_#{event}",
      user_id: user.id,
      timestamp: Time.current
    }.merge(details)

    case event
    when :access_revoked, :handling_revocation, :tokens_revoked
      logger.error log_data.to_json
    when :monitoring_error
      logger.warn log_data.to_json
    else
      logger.info log_data.to_json
    end
  end
end

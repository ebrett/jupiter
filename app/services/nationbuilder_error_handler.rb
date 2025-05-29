require_relative "nationbuilder_oauth_errors"
require_relative "nationbuilder_access_monitor"
require_relative "nationbuilder_notification_service"
require_relative "nationbuilder_graceful_degradation"
require_relative "nationbuilder_audit_logger"

class NationbuilderErrorHandler
  include NationbuilderOauthErrors

  attr_reader :user, :logger, :access_monitor, :notification_service, :graceful_degradation, :audit_logger

  def initialize(user:, logger: Rails.logger)
    @user = user
    @logger = logger
    @access_monitor = NationbuilderAccessMonitor.new(user: user, logger: logger)
    @notification_service = NationbuilderNotificationService.new(logger: logger)
    @graceful_degradation = NationbuilderGracefulDegradation.new(user: user, logger: logger)
    @audit_logger = NationbuilderAuditLogger.new(logger: logger)
  end

  # Main error handling entry point
  def handle_error(error, context: {})
    log_error(error, context)

    # Check for access revocation first
    if access_monitor.detect_revocation_from_error(error)
      return handle_access_revocation(error, context)
    end

    strategy = RecoveryStrategy.for_error(error)

    case strategy
    when :reauthenticate
      handle_reauthentication_required(error, context)
    when :refresh_token
      handle_token_refresh_required(error, context)
    when :wait_and_retry
      handle_rate_limit(error, context)
    when :retry_with_backoff
      handle_retry_with_backoff(error, context)
    when :admin_intervention
      handle_admin_intervention_required(error, context)
    else
      handle_unrecoverable_error(error, context)
    end
  end

  # Handle access revocation specifically
  def handle_access_revocation(error, context = {})
    log_authentication_event(:access_revocation_detected, error: error, context: context)

    # Use the access monitor to handle revocation cleanup
    access_monitor.handle_access_revocation

    # Create specific revocation notification
    create_user_notification(
      type: :access_revoked,
      title: "Access Revoked",
      message: "Your authorization has been revoked. Please log in again to restore access.",
      error: error,
      priority: :high
    )

    # Check if this is a global revocation affecting all tokens
    if access_monitor.global_revocation_detected?
      create_admin_notification(
        type: :global_revocation,
        title: "Global Access Revocation Detected",
        message: "User #{user.id} appears to have revoked app-wide access.",
        error: error,
        user: user
      )
    end

    {
      strategy: :access_revoked,
      action_taken: :tokens_revoked,
      user_notification: true,
      requires_user_action: true,
      global_revocation: access_monitor.global_revocation_detected?
    }
  end

  # Handle errors that require user re-authentication
  def handle_reauthentication_required(error, context = {})
    log_authentication_event(:reauthentication_required, error: error, context: context)

    # Mark user's tokens as invalid
    invalidate_user_tokens(reason: error.class.name)

    # Create notification for user
    create_user_notification(
      type: :reauthentication_required,
      title: "Re-authentication Required",
      message: build_reauthentication_message(error),
      error: error
    )

    # Trigger reauthentication flow
    trigger_reauthentication_flow(error)

    {
      strategy: :reauthentication_required,
      action_taken: :tokens_invalidated,
      user_notification: true,
      requires_user_action: true
    }
  end

  # Handle errors that can be resolved by refreshing tokens
  def handle_token_refresh_required(error, context = {})
    log_authentication_event(:token_refresh_attempted, error: error, context: context)

    current_token = user.nationbuilder_tokens.order(created_at: :desc).first
    return handle_reauthentication_required(error, context) unless current_token

    begin
      success = current_token.refresh!

      if success
        log_authentication_event(:token_refresh_successful, token_id: current_token.id)
        {
          strategy: :token_refresh,
          action_taken: :tokens_refreshed,
          success: true,
          can_retry: true
        }
      else
        # Refresh failed, escalate to reauthentication
        handle_reauthentication_required(
          InvalidRefreshTokenError.new("Token refresh failed"),
          context.merge(original_error: error)
        )
      end
    rescue => refresh_error
      log_error(refresh_error, context.merge(during_recovery: true))
      # Escalate to reauthentication
      handle_reauthentication_required(refresh_error, context)
    end
  end

  # Handle rate limiting
  def handle_rate_limit(error, context = {})
    retry_delay = RecoveryStrategy.retry_delay(error)

    log_authentication_event(:rate_limit_encountered,
      retry_delay: retry_delay,
      error: error
    )

    # Create notification for user about temporary delay
    create_user_notification(
      type: :rate_limit,
      title: "Service Temporarily Unavailable",
      message: "Please wait #{retry_delay} seconds before trying again.",
      error: error,
      temporary: true
    )

    {
      strategy: :wait_and_retry,
      action_taken: :rate_limit_applied,
      retry_delay: retry_delay,
      can_retry: true
    }
  end

  # Handle network/server errors with backoff
  def handle_retry_with_backoff(error, context = {})
    attempt_count = context[:attempt_count] || 1
    retry_delay = RecoveryStrategy.retry_delay(error, attempt_count)

    log_authentication_event(:retry_with_backoff,
      attempt_count: attempt_count,
      retry_delay: retry_delay,
      error: error
    )

    {
      strategy: :retry_with_backoff,
      action_taken: :backoff_applied,
      retry_delay: retry_delay,
      attempt_count: attempt_count,
      can_retry: RecoveryStrategy.should_retry?(error, attempt_count)
    }
  end

  # Handle errors that require admin intervention
  def handle_admin_intervention_required(error, context = {})
    log_authentication_event(:admin_intervention_required, error: error, context: context)

    # Create admin notification
    create_admin_notification(
      type: :configuration_error,
      title: "OAuth Configuration Issue",
      message: "OAuth configuration error requires admin attention: #{error.message}",
      error: error,
      user: user
    )

    # Create user notification
    create_user_notification(
      type: :service_unavailable,
      title: "Service Temporarily Unavailable",
      message: "We're experiencing technical difficulties. Please try again later.",
      error: error,
      show_details: false
    )

    {
      strategy: :admin_intervention,
      action_taken: :notifications_sent,
      requires_admin_action: true,
      user_notification: true
    }
  end

  # Handle unrecoverable errors with graceful degradation
  def handle_unrecoverable_error(error, context = {})
    log_authentication_event(:unrecoverable_error, error: error, context: context)

    # Check if we can provide degraded functionality
    degraded_response = attempt_graceful_degradation(error, context)

    if degraded_response[:available]
      create_user_notification(
        type: :degraded_service,
        title: "Limited Service Mode",
        message: degraded_response[:message],
        error: error,
        show_details: false,
        priority: :medium
      )

      {
        strategy: :graceful_degradation,
        action_taken: :degraded_service_provided,
        degraded_response: degraded_response,
        user_notification: true,
        requires_user_action: false
      }
    else
      create_user_notification(
        type: :error,
        title: "Connection Error",
        message: "Unable to connect to authentication service. Please try again later.",
        error: error,
        show_details: false
      )

      {
        strategy: :log_and_fail,
        action_taken: :error_logged,
        user_notification: true,
        requires_user_action: false
      }
    end
  end

  # Attempt to provide graceful degradation
  def attempt_graceful_degradation(error, context)
    feature_status = graceful_degradation.feature_status_summary
    current_level = graceful_degradation.current_feature_level

    if current_level != :none
      {
        available: true,
        level: current_level,
        message: graceful_degradation.send(:generate_degradation_message),
        features: feature_status[:features],
        recovery_action: graceful_degradation.send(:suggest_recovery_action)
      }
    else
      {
        available: false,
        level: :none,
        message: "No functionality available without authentication."
      }
    end
  end

  # Check if a token is recoverable
  def token_recoverable?(token)
    return false unless token
    return false if token.refresh_token.blank?
    return false if token_revoked?(token)

    true
  end

  # Detect if user has revoked access
  def detect_access_revocation(error)
    case error
    when AccessRevokedError
      true
    when InvalidRefreshTokenError
      # Check if the error indicates revocation vs expiration
      error.error_code == "access_denied" ||
      error.error_description&.include?("revoked") ||
      error.http_status == 403
    else
      false
    end
  end

  private

  def invalidate_user_tokens(reason:)
    user.nationbuilder_tokens.update_all(
      expires_at: Time.current,
      updated_at: Time.current
    )

    log_authentication_event(:tokens_invalidated, reason: reason, user_id: user.id)
  end

  def token_revoked?(token)
    # This could be enhanced to check a revocation list or make a test API call
    # For now, we'll rely on the error handling to detect revocation
    false
  end

  def trigger_reauthentication_flow(error)
    # Send immediate re-authentication prompt
    notification_service.send_reauthentication_prompt(
      user: user,
      reason: error.class.name,
      redirect_url: determine_redirect_url(error)
    )

    log_authentication_event(:reauthentication_flow_triggered,
      error_type: error.class.name,
      user_id: user.id
    )
  end

  def determine_redirect_url(error)
    # Determine where to redirect after re-authentication
    # This could be based on the current context, error type, etc.
    case error
    when ScopeError
      "/auth/nationbuilder?scope=extended"
    else
      "/auth/nationbuilder"
    end
  end

  def build_reauthentication_message(error)
    case error
    when AccessRevokedError
      "Your access has been revoked. Please log in again to restore access to your account."
    when InvalidRefreshTokenError
      "Your session has expired. Please log in again to continue."
    when ScopeError
      "Additional permissions are required. Please log in again to grant access."
    else
      "Please log in again to continue using the service."
    end
  end

  def create_user_notification(type:, title:, message:, error: nil, temporary: false, show_details: true, priority: :medium, **options)
    notification_service.notify_user(
      user: user,
      notification_type: type,
      title: title,
      message: message,
      error: error,
      priority: priority,
      dismissible: !temporary,
      show_details: show_details,
      **options
    )
  end

  def create_admin_notification(type:, title:, message:, error:, user:, severity: :high, **options)
    notification_service.notify_admin(
      notification_type: type,
      title: title,
      message: message,
      error: error,
      user: user,
      severity: severity,
      **options
    )
  end

  def log_error(error, context = {})
    # Log to audit logger with enhanced details
    audit_logger.log_event(:system, :oauth_error, {
      error_type: error.class.name,
      error_message: error.message,
      user_id: user.id,
      context: context,
      error_details: error.respond_to?(:loggable_details) ? error.loggable_details : nil,
      correlation_id: context[:correlation_id] || generate_correlation_id
    })

    # Also log to standard logger for immediate debugging
    log_data = {
      event: :oauth_error,
      error_type: error.class.name,
      error_message: error.message,
      user_id: user.id,
      context: context,
      timestamp: Time.current
    }

    if error.respond_to?(:loggable_details)
      log_data.merge!(error.loggable_details)
    end

    logger.error log_data.to_json
  end

  def log_authentication_event(event, **details)
    # Log to audit logger for authentication events
    audit_logger.log_authentication_event(event, user: user, details: details)

    # Also log to standard logger
    log_data = {
      event: event,
      user_id: user.id,
      timestamp: Time.current
    }.merge(details)

    logger.info log_data.to_json
  end

  private

  def generate_correlation_id
    "corr_#{SecureRandom.hex(6)}"
  end
end

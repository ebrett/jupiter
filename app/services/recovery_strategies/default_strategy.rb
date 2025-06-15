require_relative "base_recovery_strategy"

class DefaultStrategy < BaseRecoveryStrategy
  def self.can_handle?(error)
    # This strategy handles any error not handled by other strategies
    true
  end

  def execute
    log_recovery_attempt(:default_strategy, {
      error_type: error.class.name,
      error_message: error.message
    })

    # Check if we should notify admins
    if should_notify_admin?
      notify_admin_of_unknown_error
    end

    # Always notify user with a generic message
    notification_service.notify_user(
      user: user,
      notification_type: :error,
      title: "Service Error",
      message: user_friendly_error_message,
      error: error,
      priority: :medium,
      dismissible: true,
      show_details: false # Don't show technical details to users
    )

    # Log the unhandled error
    audit_logger.log_event(:system, :unhandled_oauth_error, {
      error_type: error.class.name,
      error_message: error.message,
      user_id: user.id,
      context: context,
      stack_trace: error.backtrace&.first(10) # First 10 lines of stack trace
    })

    {
      strategy: :log_and_fail,
      action_taken: :error_logged,
      user_notification: true,
      admin_notification: should_notify_admin?,
      requires_user_action: false,
      error_logged: true
    }
  end

  private

  def should_notify_admin?
    # Notify admin for configuration errors or unknown OAuth errors
    error.is_a?(NationbuilderOauthErrors::ConfigurationError) ||
      error.is_a?(NationbuilderOauthErrors::OAuthError) ||
      context[:critical] == true
  end

  def notify_admin_of_unknown_error
    notification_service.notify_admin(
      notification_type: :unknown_error,
      title: "Unknown OAuth Error",
      message: "An unhandled OAuth error occurred for user #{user.id}: #{error.class.name}",
      error: error,
      user: user,
      severity: :high,
      context: context
    )
  end

  def user_friendly_error_message
    case error
    when NationbuilderOauthErrors::ConfigurationError
      "We're experiencing technical difficulties with our authentication service. Our team has been notified."
    when NationbuilderOauthErrors::OAuthError
      "There was a problem connecting to your account. Please try again or contact support if the issue persists."
    else
      "An unexpected error occurred. Please try again later."
    end
  end
end

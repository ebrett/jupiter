require_relative "base_recovery_strategy"

module RecoveryStrategies
  class ReauthenticationStrategy < BaseRecoveryStrategy
  def self.can_handle?(error)
    error.is_a?(NationbuilderOauthErrors::InvalidRefreshTokenError) ||
      error.is_a?(NationbuilderOauthErrors::AccessRevokedError) ||
      (error.respond_to?(:requires_reauthentication?) && error.requires_reauthentication?)
  end

  def execute
    log_recovery_attempt(:reauthentication_required)

    # Mark all user tokens as invalid
    invalidate_user_tokens

    # Create user notification
    notification_service.notify_user(
      user: user,
      notification_type: :reauthentication_required,
      title: "Re-authentication Required",
      message: build_reauthentication_message,
      error: error,
      priority: :high,
      dismissible: false
    )

    # Trigger reauthentication flow
    trigger_reauthentication_flow

    # Log the event in audit log
    audit_logger.log_authentication_event(:reauthentication_required,
      user: user,
      details: {
        error_type: error.class.name,
        error_code: error.respond_to?(:error_code) ? error.error_code : nil,
        tokens_invalidated: user.nationbuilder_tokens.count
      }
    )

    {
      strategy: :reauthentication_required,
      action_taken: :tokens_invalidated,
      user_notification: true,
      requires_user_action: true,
      redirect_url: determine_redirect_url
    }
  end

  private

  def invalidate_user_tokens
    count = user.nationbuilder_tokens.update_all(
      expires_at: Time.current,
      updated_at: Time.current
    )

    log_recovery_attempt(:tokens_invalidated, { count: count, reason: error.class.name })
  end

  def build_reauthentication_message
    case error
    when NationbuilderOauthErrors::AccessRevokedError
      "Your access has been revoked. Please log in again to restore access to your account."
    when NationbuilderOauthErrors::InvalidRefreshTokenError
      "Your session has expired. Please log in again to continue."
    when NationbuilderOauthErrors::ScopeError
      "Additional permissions are required. Please log in again to grant access."
    else
      "Please log in again to continue using the service."
    end
  end

  def trigger_reauthentication_flow
    notification_service.send_reauthentication_prompt(
      user: user,
      reason: error.class.name,
      redirect_url: determine_redirect_url
    )

    log_recovery_attempt(:reauthentication_flow_triggered, {
      redirect_url: determine_redirect_url
    })
  end

  def determine_redirect_url
    case error
    when NationbuilderOauthErrors::ScopeError
      "/auth/nationbuilder?scope=extended"
    else
      "/auth/nationbuilder"
    end
  end
  end
end

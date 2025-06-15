require_relative "base_recovery_strategy"

module RecoveryStrategies
  class TokenRefreshStrategy < BaseRecoveryStrategy
  def self.can_handle?(error)
    error.is_a?(NationbuilderOauthErrors::InvalidAccessTokenError) ||
      (error.respond_to?(:can_retry_with_refresh?) && error.can_retry_with_refresh?)
  end

  def execute
    log_recovery_attempt(:token_refresh)

    current_token = user.nationbuilder_tokens.order(created_at: :desc).first

    unless current_token
      log_recovery_failure(:token_refresh, "No token found for user")
      return escalate_to_reauthentication
    end

    unless current_token.refresh_token.present?
      log_recovery_failure(:token_refresh, "No refresh token available")
      return escalate_to_reauthentication
    end

    begin
      success = current_token.refresh!

      if success
        log_recovery_attempt(:token_refresh_successful, { token_id: current_token.id })
        audit_logger.log_token_event(:token_refreshed,
          user: user,
          details: {
            token_id: current_token.id,
            expires_at: current_token.expires_at,
            triggered_by_error: error.class.name
          }
        )

        {
          strategy: :token_refresh,
          action_taken: :tokens_refreshed,
          success: true,
          can_retry: true
        }
      else
        log_recovery_failure(:token_refresh, "Token refresh returned false")
        escalate_to_reauthentication
      end
    rescue => refresh_error
      log_recovery_failure(:token_refresh, refresh_error.message, {
        refresh_error_type: refresh_error.class.name
      })

      # Log the refresh failure in audit log
      audit_logger.log_token_event(:token_refresh_failed,
        user: user,
        details: {
          token_id: current_token.id,
          original_error: error.class.name,
          refresh_error: refresh_error.class.name,
          refresh_error_message: refresh_error.message
        }
      )

      escalate_to_reauthentication
    end
  end

  private

  def escalate_to_reauthentication
    # Create a reauthentication required error and use that strategy
    reauth_error = NationbuilderOauthErrors::InvalidRefreshTokenError.new(
      "Token refresh failed, reauthentication required",
      error_code: "refresh_failed",
      error_description: "Unable to refresh access token"
    )

    RecoveryStrategies::ReauthenticationStrategy.new(
      user: user,
      error: reauth_error,
      context: context.merge(original_error: error)
    ).execute
  end
  end
end

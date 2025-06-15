require_relative "base_recovery_strategy"

class NetworkRetryStrategy < BaseRecoveryStrategy
  MAX_RETRIES = 3
  BASE_DELAY = 2 # seconds

  def self.can_handle?(error)
    error.is_a?(NationbuilderOauthErrors::NetworkError) ||
      error.is_a?(NationbuilderOauthErrors::ServerError) ||
      error.is_a?(Net::ReadTimeout) ||
      error.is_a?(Net::OpenTimeout)
  end

  def execute
    attempt_count = context[:attempt_count] || 1
    can_retry = attempt_count < MAX_RETRIES
    retry_delay = calculate_retry_delay(attempt_count)

    log_recovery_attempt(:network_retry, {
      attempt_count: attempt_count,
      retry_delay: retry_delay,
      can_retry: can_retry,
      error_class: error.class.name
    })

    if can_retry
      # Log the retry attempt
      audit_logger.log_api_event(:network_error_retry,
        user: user,
        endpoint: context[:path],
        details: {
          attempt_count: attempt_count,
          retry_delay: retry_delay,
          error_type: error.class.name,
          error_message: error.message,
          correlation_id: context[:correlation_id]
        }
      )

      {
        strategy: :retry_with_backoff,
        action_taken: :backoff_applied,
        retry_delay: retry_delay,
        attempt_count: attempt_count,
        can_retry: true
      }
    else
      log_recovery_failure(:network_retry, "Max retries exceeded", {
        total_attempts: attempt_count
      })

      # Notify user of persistent network issues
      notification_service.notify_user(
        user: user,
        notification_type: :network_error,
        title: "Connection Problem",
        message: "Unable to connect to the authentication service. Please check your internet connection and try again.",
        error: error,
        priority: :medium,
        dismissible: true
      )

      {
        strategy: :retry_with_backoff,
        action_taken: :max_retries_exceeded,
        retry_delay: 0,
        attempt_count: attempt_count,
        can_retry: false
      }
    end
  end

  private

  def calculate_retry_delay(attempt_count)
    # Exponential backoff with jitter
    base_delay = BASE_DELAY ** attempt_count
    jitter = rand(0.5..1.5)
    delay = base_delay * jitter

    # Cap at 5 minutes
    [ delay, 300 ].min
  end
end

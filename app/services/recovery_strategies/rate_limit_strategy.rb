require_relative "base_recovery_strategy"

module RecoveryStrategies
  class RateLimitStrategy < BaseRecoveryStrategy
  def self.can_handle?(error)
    error.is_a?(NationbuilderOauthErrors::RateLimitError)
  end

  def execute
    retry_delay = calculate_retry_delay

    log_recovery_attempt(:rate_limit_encountered, {
      retry_delay: retry_delay,
      retry_after: error.retry_after,
      reset_time: error.reset_time
    })

    # Create temporary notification for user
    notification_service.notify_user(
      user: user,
      notification_type: :rate_limit,
      title: "Service Temporarily Unavailable",
      message: "Too many requests. Please wait #{humanize_duration(retry_delay)} before trying again.",
      error: error,
      priority: :medium,
      dismissible: true,
      auto_dismiss_after: retry_delay
    )

    # Log in audit log
    audit_logger.log_api_event(:rate_limit_exceeded,
      user: user,
      endpoint: context[:path],
      details: {
        retry_delay: retry_delay,
        retry_after_header: error.retry_after,
        reset_time: error.reset_time,
        correlation_id: context[:correlation_id]
      }
    )

    # Store rate limit info for future requests
    cache_rate_limit_info(retry_delay)

    {
      strategy: :wait_and_retry,
      action_taken: :rate_limit_applied,
      retry_delay: retry_delay,
      can_retry: true,
      reset_time: error.reset_time
    }
  end

  private

  def calculate_retry_delay
    if error.retry_after
      error.retry_after
    elsif error.reset_time && error.reset_time > Time.current
      (error.reset_time - Time.current).to_i
    else
      60 # Default to 60 seconds
    end
  end

  def humanize_duration(seconds)
    if seconds < 60
      "#{seconds} seconds"
    elsif seconds < 3600
      minutes = (seconds / 60).round
      "#{minutes} minute#{'s' if minutes != 1}"
    else
      hours = (seconds / 3600).round
      "#{hours} hour#{'s' if hours != 1}"
    end
  end

  def cache_rate_limit_info(retry_delay)
    cache_key = "rate_limit:#{user.id}:nationbuilder"
    Rails.cache.write(cache_key, {
      limited_until: Time.current + retry_delay,
      retry_delay: retry_delay,
      endpoint: context[:path]
    }, expires_in: retry_delay)
  end
  end
end

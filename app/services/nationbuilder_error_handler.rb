require_relative "nationbuilder_oauth_errors"
require_relative "recovery_strategies/base_recovery_strategy"
require_relative "recovery_strategies/token_refresh_strategy"
require_relative "recovery_strategies/reauthentication_strategy"
require_relative "recovery_strategies/rate_limit_strategy"
require_relative "recovery_strategies/network_retry_strategy"
require_relative "recovery_strategies/default_strategy"

class NationbuilderErrorHandler
  include NationbuilderOauthErrors

  attr_reader :user, :logger, :strategies

  def initialize(user:, logger: Rails.logger, strategies: nil)
    @user = user
    @logger = logger
    @strategies = strategies || default_strategies
  end

  # Main error handling entry point
  def handle_error(error, context: {})
    log_error_occurrence(error, context)

    # Find the appropriate strategy
    strategy_class = find_strategy_for_error(error)

    # Execute the strategy
    strategy = strategy_class.new(
      user: user,
      error: error,
      context: context,
      logger: logger
    )

    result = strategy.execute

    # Log the recovery result
    log_recovery_result(error, result, context)

    result
  rescue => recovery_error
    # If the recovery itself fails, log and return a safe default
    log_recovery_failure(error, recovery_error, context)

    {
      strategy: :recovery_failed,
      action_taken: :none,
      original_error: error.class.name,
      recovery_error: recovery_error.class.name,
      requires_user_action: true
    }
  end

  # Check if an error is recoverable
  def recoverable?(error)
    strategy_class = find_strategy_for_error(error)

    # Default strategy means we don't have a specific recovery path
    strategy_class != DefaultStrategy
  end

  # Get recovery metadata for an error
  def recovery_metadata(error)
    strategy_class = find_strategy_for_error(error)

    {
      strategy: strategy_class.name.underscore.gsub(/_strategy$/, ""),
      can_retry: can_retry?(error),
      requires_user_action: requires_user_action?(error),
      requires_admin_action: requires_admin_action?(error)
    }
  end

  private

  def default_strategies
    [
      TokenRefreshStrategy,
      ReauthenticationStrategy,
      RateLimitStrategy,
      NetworkRetryStrategy,
      DefaultStrategy # Must be last as it handles everything
    ]
  end

  def find_strategy_for_error(error)
    strategies.find { |strategy| strategy.can_handle?(error) } || DefaultStrategy
  end

  def can_retry?(error)
    case error
    when RateLimitError, NetworkError, ServerError
      true
    when InvalidAccessTokenError
      # Can retry if we have a refresh token
      user.nationbuilder_tokens.exists?("refresh_token IS NOT NULL")
    else
      false
    end
  end

  def requires_user_action?(error)
    case error
    when InvalidRefreshTokenError, AccessRevokedError, ScopeError
      true
    else
      false
    end
  end

  def requires_admin_action?(error)
    error.is_a?(ConfigurationError) ||
      (error.respond_to?(:requires_admin_intervention?) && error.requires_admin_intervention?)
  end

  def log_error_occurrence(error, context)
    logger.error({
      event: "oauth_error_occurred",
      error_type: error.class.name,
      error_message: error.message,
      user_id: user.id,
      context: context,
      error_details: error.respond_to?(:to_h) ? error.to_h : nil
    }.to_json)
  end

  def log_recovery_result(error, result, context)
    logger.info({
      event: "oauth_error_recovery",
      error_type: error.class.name,
      recovery_strategy: result[:strategy],
      recovery_success: result[:success] || false,
      action_taken: result[:action_taken],
      user_id: user.id,
      context: context
    }.to_json)
  end

  def log_recovery_failure(original_error, recovery_error, context)
    logger.error({
      event: "oauth_recovery_failed",
      original_error_type: original_error.class.name,
      recovery_error_type: recovery_error.class.name,
      recovery_error_message: recovery_error.message,
      user_id: user.id,
      context: context,
      stack_trace: recovery_error.backtrace&.first(5)
    }.to_json)
  end
end

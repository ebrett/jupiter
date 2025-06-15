# Base class for all recovery strategies
class BaseRecoveryStrategy
  attr_reader :user, :error, :context, :logger

  def initialize(user:, error:, context: {}, logger: Rails.logger)
    @user = user
    @error = error
    @context = context
    @logger = logger
  end

  # Subclasses must implement this method to determine if they can handle the error
  def self.can_handle?(error)
    raise NotImplementedError, "Subclasses must implement .can_handle?"
  end

  # Execute the recovery strategy
  def execute
    raise NotImplementedError, "Subclasses must implement #execute"
  end

  protected

  def log_recovery_attempt(action, details = {})
    logger.info({
      recovery_strategy: self.class.name,
      action: action,
      user_id: user.id,
      error_type: error.class.name,
      details: details
    }.to_json)
  end

  def log_recovery_failure(action, failure_reason, details = {})
    logger.error({
      recovery_strategy: self.class.name,
      action: action,
      failure_reason: failure_reason,
      user_id: user.id,
      error_type: error.class.name,
      details: details
    }.to_json)
  end

  def audit_logger
    @audit_logger ||= NationbuilderAuditLogger.new(logger: logger)
  end

  def notification_service
    @notification_service ||= NationbuilderNotificationService.new(logger: logger)
  end
end

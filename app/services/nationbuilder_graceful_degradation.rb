require_relative "nationbuilder_oauth_errors"

class NationbuilderGracefulDegradation
  include NationbuilderOauthErrors

  attr_reader :user, :logger

  # Feature availability levels
  FEATURE_LEVELS = {
    full: :full_functionality,
    limited: :limited_functionality,
    readonly: :readonly_access,
    offline: :offline_mode,
    none: :no_access
  }.freeze

  # Features that can be degraded
  DEGRADABLE_FEATURES = {
    data_sync: {
      full: :real_time_sync,
      limited: :periodic_sync,
      readonly: :read_cached_data,
      offline: :show_last_known_data,
      none: :feature_disabled
    },
    user_profiles: {
      full: :full_profile_access,
      limited: :basic_profile_only,
      readonly: :cached_profile_data,
      offline: :local_profile_copy,
      none: :feature_disabled
    },
    contact_management: {
      full: :full_crud_operations,
      limited: :read_and_create_only,
      readonly: :view_only,
      offline: :cached_contacts,
      none: :feature_disabled
    },
    reporting: {
      full: :live_reports,
      limited: :basic_reports_only,
      readonly: :cached_reports,
      offline: :last_generated_reports,
      none: :feature_disabled
    },
    bulk_operations: {
      full: :all_bulk_operations,
      limited: :small_batch_only,
      readonly: :no_bulk_operations,
      offline: :queue_for_later,
      none: :feature_disabled
    }
  }.freeze

  def initialize(user: nil, logger: Rails.logger)
    @user = user
    @logger = logger
  end

  # Determine the current feature level based on authentication status
  def current_feature_level
    return :none unless user

    token = current_token
    return :none unless token

    if token.valid_for_api_use?
      :full
    elsif token.refresh_token.present? && !token_revoked?(token)
      :limited # Can try to refresh
    elsif has_cached_data?
      :readonly # Can show cached data
    elsif has_offline_capabilities?
      :offline # Can work in offline mode
    else
      :none
    end
  end

  # Check if a specific feature is available at current authentication level
  def feature_available?(feature_name, required_level: :full)
    current_level = current_feature_level
    feature_config = DEGRADABLE_FEATURES[feature_name.to_sym]

    return false unless feature_config

    # Check if current level supports the required level
    level_hierarchy = [ :none, :offline, :readonly, :limited, :full ]
    current_index = level_hierarchy.index(current_level) || 0
    required_index = level_hierarchy.index(required_level) || 0

    current_index >= required_index
  end

  # Get the available functionality for a feature at current level
  def feature_functionality(feature_name)
    current_level = current_feature_level
    feature_config = DEGRADABLE_FEATURES[feature_name.to_sym]

    return :feature_not_configured unless feature_config

    feature_config[current_level] || :feature_disabled
  end

  # Gracefully handle API operations with fallbacks
  def execute_with_fallback(operation_name, primary_action:, fallback_actions: {}, &block)
    log_degradation_event(:operation_attempted, operation: operation_name)

    begin
      # Try the primary action first
      result = primary_action.call
      log_degradation_event(:operation_succeeded, operation: operation_name, method: :primary)
      result
    rescue OAuthError => e
      handle_degraded_operation(operation_name, e, fallback_actions, &block)
    end
  end

  # Provide degraded data access with multiple fallback layers
  def get_data_with_fallbacks(data_type, primary_fetch:, cache_fetch: nil, default_data: nil)
    log_degradation_event(:data_fetch_attempted, data_type: data_type)

    begin
      # Try primary data source (API)
      data = primary_fetch.call
      cache_data(data_type, data) if data # Cache successful results
      log_degradation_event(:data_fetch_succeeded, data_type: data_type, method: :primary)
      data
    rescue OAuthError => e
      log_degradation_event(:data_fetch_failed, data_type: data_type, error: e.class.name)

      # Fall back to cached data
      if cache_fetch
        begin
          cached_data = cache_fetch.call
          if cached_data
            log_degradation_event(:data_fetch_succeeded, data_type: data_type, method: :cache)
            return add_staleness_warning(cached_data)
          end
        rescue => cache_error
          log_degradation_event(:cache_fetch_failed, data_type: data_type, error: cache_error.message)
        end
      end

      # Fall back to default data
      if default_data
        log_degradation_event(:data_fetch_succeeded, data_type: data_type, method: :default)
        return add_unavailability_notice(default_data)
      end

      # No fallback available
      log_degradation_event(:data_fetch_exhausted, data_type: data_type)
      raise DataUnavailableError.new("Data not available: #{e.message}")
    end
  end

  # Create a feature-limited version of functionality
  def create_limited_feature(feature_name, full_implementation:, limited_implementation: nil)
    current_level = current_feature_level

    case current_level
    when :full
      full_implementation.call
    when :limited, :readonly
      if limited_implementation
        log_degradation_event(:feature_degraded, feature: feature_name, level: current_level)
        limited_implementation.call
      else
        create_feature_unavailable_response(feature_name, "Feature temporarily limited")
      end
    else
      create_feature_unavailable_response(feature_name, "Feature currently unavailable")
    end
  end

  # Handle operations that require authentication with graceful degradation
  def authenticated_operation(operation_name, &block)
    current_level = current_feature_level

    case current_level
    when :full
      # Full functionality available
      yield
    when :limited
      # Try to refresh token and retry
      if attempt_token_refresh
        log_degradation_event(:token_refresh_succeeded, operation: operation_name)
        yield
      else
        raise AuthenticationRequiredError.new("Authentication required for #{operation_name}")
      end
    else
      # No authentication available
      raise AuthenticationUnavailableError.new("Authentication unavailable for #{operation_name}")
    end
  end

  # Create a degraded response with appropriate messaging
  def create_degraded_response(original_data: nil, message: nil, available_actions: [])
    {
      status: :degraded,
      data: original_data,
      degradation_message: message || generate_degradation_message,
      feature_level: current_feature_level,
      available_actions: available_actions,
      timestamp: Time.current,
      requires_authentication: authentication_required?
    }
  end

  # Get status of all features given current authentication state
  def feature_status_summary
    current_level = current_feature_level

    summary = {
      overall_status: current_level,
      authentication_available: current_token&.valid_for_api_use? || false,
      can_refresh: can_attempt_refresh?,
      features: {}
    }

    DEGRADABLE_FEATURES.each do |feature_name, config|
      summary[:features][feature_name] = {
        available: feature_available?(feature_name),
        functionality: feature_functionality(feature_name),
        required_level: determine_minimum_level(feature_name)
      }
    end

    summary
  end

  # Queue operations for when authentication is restored
  def queue_for_later(operation_name, operation_data)
    queued_operation = {
      id: generate_operation_id,
      operation: operation_name,
      data: operation_data,
      user_id: user&.id,
      queued_at: Time.current,
      status: :pending
    }

    store_queued_operation(queued_operation)
    log_degradation_event(:operation_queued, operation: operation_name, queue_id: queued_operation[:id])

    queued_operation
  end

  # Process queued operations when authentication is restored
  def process_queued_operations
    return [] unless user && current_feature_level == :full

    queued_operations = get_queued_operations
    processed = []

    queued_operations.each do |operation|
      begin
        result = execute_queued_operation(operation)
        mark_operation_completed(operation[:id])
        processed << { operation: operation, result: result, status: :completed }
        log_degradation_event(:queued_operation_completed, queue_id: operation[:id])
      rescue => e
        mark_operation_failed(operation[:id], e.message)
        processed << { operation: operation, error: e.message, status: :failed }
        log_degradation_event(:queued_operation_failed, queue_id: operation[:id], error: e.message)
      end
    end

    processed
  end

  private

  def current_token
    return nil unless user
    user.nationbuilder_tokens.order(created_at: :desc).first
  end

  def token_revoked?(token)
    # Simple revocation check - could be enhanced
    false
  end

  def has_cached_data?
    # Check if we have any cached data available
    # This would typically check cache stores, local storage, etc.
    true # Placeholder
  end

  def has_offline_capabilities?
    # Check if offline mode is supported
    # This could check for service workers, local storage, etc.
    false # Placeholder
  end

  def attempt_token_refresh
    token = current_token
    return false unless token&.refresh_token.present?

    begin
      token.refresh!
    rescue => e
      log_degradation_event(:token_refresh_failed, error: e.message)
      false
    end
  end

  def handle_degraded_operation(operation_name, error, fallback_actions, &block)
    # Try fallback actions in order
    fallback_actions.each do |level, action|
      if feature_available?(operation_name, required_level: level)
        begin
          result = action.call
          log_degradation_event(:operation_succeeded, operation: operation_name, method: level)
          return result
        rescue => fallback_error
          log_degradation_event(:fallback_failed, operation: operation_name, level: level, error: fallback_error.message)
          next
        end
      end
    end

    # If custom block provided for handling degradation
    if block_given?
      return yield(error)
    end

    # All fallbacks exhausted
    log_degradation_event(:operation_failed, operation: operation_name)
    raise OperationDegradedError.new("Operation #{operation_name} unavailable: #{error.message}")
  end

  def cache_data(data_type, data)
    # Cache data for offline access
    # This would typically use Rails.cache, Redis, etc.
    logger.debug "Caching #{data_type} data"
  end

  def add_staleness_warning(data)
    if data.is_a?(Hash)
      data.merge(
        _cache_warning: "This data may be outdated. Last updated: #{Time.current}",
        _data_source: "cache"
      )
    else
      data
    end
  end

  def add_unavailability_notice(data)
    if data.is_a?(Hash)
      data.merge(
        _availability_notice: "Live data unavailable. Showing default/placeholder data.",
        _data_source: "default"
      )
    else
      data
    end
  end

  def create_feature_unavailable_response(feature_name, message)
    {
      feature: feature_name,
      available: false,
      message: message,
      current_level: current_feature_level,
      required_level: determine_minimum_level(feature_name),
      suggested_action: suggest_recovery_action
    }
  end

  def generate_degradation_message
    case current_feature_level
    when :limited
      "Some features are temporarily limited. Please refresh your connection."
    when :readonly
      "You're in read-only mode. Some features are unavailable."
    when :offline
      "You're in offline mode. Only cached data is available."
    when :none
      "Please log in to access all features."
    else
      "Service is operating normally."
    end
  end

  def authentication_required?
    [ :none, :offline ].include?(current_feature_level)
  end

  def can_attempt_refresh?
    current_token&.refresh_token.present? && !token_revoked?(current_token)
  end

  def determine_minimum_level(feature_name)
    config = DEGRADABLE_FEATURES[feature_name.to_sym]
    return :full unless config

    # Find the minimum level where the feature is not disabled
    config.each do |level, functionality|
      return level unless functionality == :feature_disabled
    end

    :full
  end

  def suggest_recovery_action
    case current_feature_level
    when :limited
      "Try refreshing the page or re-authenticating"
    when :readonly, :offline
      "Please log in again to restore full functionality"
    when :none
      "Please log in to access features"
    else
      nil
    end
  end

  def generate_operation_id
    "op_#{SecureRandom.hex(8)}"
  end

  def store_queued_operation(operation)
    # Store operation for later processing
    # This would typically use a job queue, database, etc.
    logger.info "Queued operation: #{operation.to_json}"
  end

  def get_queued_operations
    # Retrieve queued operations for the user
    # This would typically query a database or job queue
    []
  end

  def execute_queued_operation(operation)
    # Execute a previously queued operation
    # This would depend on the operation type
    logger.info "Executing queued operation: #{operation[:id]}"
    { success: true }
  end

  def mark_operation_completed(operation_id)
    logger.info "Marked operation completed: #{operation_id}"
  end

  def mark_operation_failed(operation_id, error_message)
    logger.warn "Marked operation failed: #{operation_id} - #{error_message}"
  end

  def log_degradation_event(event, **details)
    log_data = {
      event: "graceful_degradation_#{event}",
      user_id: user&.id,
      feature_level: current_feature_level,
      timestamp: Time.current
    }.merge(details)

    logger.info log_data.to_json
  end

  # Custom error classes for degradation scenarios
  class DataUnavailableError < StandardError; end
  class AuthenticationRequiredError < StandardError; end
  class AuthenticationUnavailableError < StandardError; end
  class OperationDegradedError < StandardError; end
end

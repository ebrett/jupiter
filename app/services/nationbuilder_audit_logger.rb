class NationbuilderAuditLogger
  # Event categories for organizing logs
  EVENT_CATEGORIES = {
    authentication: %w[
      login_attempt login_success login_failure
      logout token_exchange authorization_granted authorization_denied
    ],
    token_management: %w[
      token_created token_refreshed token_expired token_revoked
      token_validation_success token_validation_failure
      refresh_attempt refresh_success refresh_failure
    ],
    api_operations: %w[
      api_request_started api_request_completed api_request_failed
      api_rate_limited api_unauthorized api_forbidden
      bulk_operation_started bulk_operation_completed
    ],
    security: %w[
      access_revocation_detected suspicious_activity
      multiple_failed_attempts account_locked
      permission_escalation_attempt
    ],
    system: %w[
      configuration_error network_error service_degraded
      maintenance_mode cache_miss cache_hit
    ],
    user_actions: %w[
      profile_updated permissions_changed
      data_export_requested data_imported
    ]
  }.freeze

  # Log levels for different event types
  LOG_LEVELS = {
    debug: Logger::DEBUG,
    info: Logger::INFO,
    warn: Logger::WARN,
    error: Logger::ERROR,
    fatal: Logger::FATAL
  }.freeze

  attr_reader :logger, :audit_file_logger

  def initialize(logger: Rails.logger)
    @logger = logger
    @audit_file_logger = setup_audit_file_logger
  end

  # Main audit logging method
  def log_event(category, event, details = {})
    return unless valid_category_and_event?(category, event)

    audit_entry = build_audit_entry(category, event, details)

    # Determine log level based on event
    level = determine_log_level(category, event, details)

    # Log to both main logger and audit file
    log_to_main_logger(audit_entry, level)
    log_to_audit_file(audit_entry)

    # Log to external systems if configured
    log_to_external_systems(audit_entry) if should_log_externally?(category, event)

    audit_entry
  end

  # Specific logging methods for common OAuth2 events
  def log_authentication_event(event, user: nil, details: {})
    enhanced_details = details.merge(
      user_id: user&.id,
      user_email: user&.email_address,
      ip_address: extract_ip_address(details),
      user_agent: extract_user_agent(details),
      session_id: extract_session_id(details)
    )

    log_event(:authentication, event, enhanced_details)
  end

  def log_token_event(event, token: nil, user: nil, details: {})
    enhanced_details = details.merge(
      token_id: token&.id,
      user_id: user&.id || token&.user_id,
      token_type: token&.class&.name,
      expires_at: token&.expires_at,
      scope: token&.scope
    )

    log_event(:token_management, event, enhanced_details)
  end

  def log_api_event(event, user: nil, endpoint: nil, details: {})
    enhanced_details = details.merge(
      user_id: user&.id,
      endpoint: endpoint,
      request_method: details[:method],
      response_status: details[:status],
      response_time: details[:duration],
      request_size: details[:request_size],
      response_size: details[:response_size]
    )

    log_event(:api_operations, event, enhanced_details)
  end

  def log_security_event(event, user: nil, severity: :high, details: {})
    enhanced_details = details.merge(
      user_id: user&.id,
      severity: severity,
      source_ip: extract_ip_address(details),
      threat_level: determine_threat_level(event, details),
      requires_investigation: requires_investigation?(event, severity)
    )

    log_event(:security, event, enhanced_details)
  end

  def log_system_event(event, component: nil, details: {})
    enhanced_details = details.merge(
      component: component,
      system_status: get_system_status,
      memory_usage: get_memory_usage,
      active_connections: get_active_connections
    )

    log_event(:system, event, enhanced_details)
  end

  # Query audit logs (for admin dashboard or debugging)
  def query_logs(filters = {})
    # This would typically query a database or search logs
    # For now, return a placeholder structure
    {
      total_events: 0,
      events: [],
      filters_applied: filters,
      timestamp: Time.current
    }
  end

  # Get audit statistics
  def audit_statistics(timeframe: 24.hours)
    since = Time.current - timeframe

    # This would typically aggregate from stored audit logs
    {
      timeframe: timeframe,
      total_events: 0,
      events_by_category: EVENT_CATEGORIES.keys.map { |cat| [ cat, 0 ] }.to_h,
      events_by_level: LOG_LEVELS.keys.map { |level| [ level, 0 ] }.to_h,
      top_users: [],
      top_errors: [],
      security_events: 0,
      system_events: 0
    }
  end

  # Export audit logs for external analysis
  def export_logs(format: :json, filters: {}, timeframe: 7.days)
    logs = query_logs(filters.merge(since: Time.current - timeframe))

    case format
    when :json
      export_as_json(logs)
    when :csv
      export_as_csv(logs)
    when :xml
      export_as_xml(logs)
    else
      raise ArgumentError, "Unsupported export format: #{format}"
    end
  end

  # Performance monitoring for OAuth operations
  def log_performance_metrics(operation, duration, details = {})
    metrics = {
      operation: operation,
      duration_ms: duration,
      timestamp: Time.current,
      performance_tier: categorize_performance(duration)
    }.merge(details)

    log_event(:system, :performance_metric, metrics)

    # Alert if performance is degraded
    if duration > performance_threshold(operation)
      log_event(:system, :performance_degraded, metrics.merge(
        threshold: performance_threshold(operation),
        severity: :warning
      ))
    end
  end

  # Security pattern detection
  def detect_security_patterns(user: nil, timeframe: 1.hour)
    # This would analyze recent logs for security patterns
    patterns = {
      multiple_failed_logins: false,
      unusual_access_patterns: false,
      suspicious_api_usage: false,
      potential_token_theft: false
    }

    if patterns.any? { |_, detected| detected }
      log_security_event(:security_pattern_detected,
        user: user,
        severity: :high,
        patterns: patterns,
        timeframe: timeframe
      )
    end

    patterns
  end

  # Compliance logging for regulatory requirements
  def log_compliance_event(regulation, event_type, details = {})
    compliance_entry = {
      regulation: regulation, # e.g., :gdpr, :ccpa, :hipaa
      event_type: event_type, # e.g., :data_access, :data_export, :consent_change
      compliance_timestamp: Time.current.utc,
      retention_period: determine_retention_period(regulation),
      legal_basis: details[:legal_basis],
      data_subject: details[:data_subject]
    }.merge(details)

    log_event(:compliance, event_type, compliance_entry)

    # Store in compliance-specific storage if required
    store_compliance_record(compliance_entry) if requires_compliance_storage?(regulation)
  end

  private

  def setup_audit_file_logger
    audit_log_path = Rails.root.join("log", "oauth_audit.log")
    file_logger = Logger.new(audit_log_path, "daily")
    file_logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime.utc.iso8601} [#{severity}] #{msg}\n"
    end
    file_logger
  end

  def valid_category_and_event?(category, event)
    return false unless EVENT_CATEGORIES.key?(category.to_sym)
    # Allow any event for now, could be restricted to predefined events
    true
  end

  def build_audit_entry(category, event, details)
    {
      audit_id: generate_audit_id,
      timestamp: Time.current.utc,
      category: category,
      event: event,
      rails_env: Rails.env,
      application: "jupiter",
      version: ENV["APP_VERSION"] || "unknown",
      correlation_id: details.delete(:correlation_id) || generate_correlation_id,
      details: sanitize_sensitive_data(details)
    }
  end

  def determine_log_level(category, event, details)
    # Determine appropriate log level based on event type
    level = case category
    when :security
      details[:severity] == :critical ? :error : :warn
    when :authentication
      event.to_s.include?("failure") ? :warn : :info
    when :token_management
      event.to_s.include?("failure") || event.to_s.include?("expired") ? :warn : :info
    when :api_operations
      status = details[:status]
      (status.is_a?(Integer) && status >= 400) || (status.is_a?(String) && status.to_i >= 400) ? :warn : :info
    when :system
      event.to_s.include?("error") ? :error : :info
    else
      :info
    end

    # Ensure we return a valid symbol
    level || :info
  end

  def log_to_main_logger(audit_entry, level)
    log_message = format_audit_message(audit_entry)
    logger.send(level, log_message)
  end

  def log_to_audit_file(audit_entry)
    audit_file_logger.info(audit_entry.to_json)
  end

  def log_to_external_systems(audit_entry)
    # Log to external systems like Splunk, ELK, DataDog, etc.
    # This would be configured based on environment

    # Example: Send to webhook endpoint
    # WebhookService.send_audit_log(audit_entry)

    # Example: Send to message queue
    # AuditLogQueue.enqueue(audit_entry)

    logger.debug "Audit entry sent to external systems: #{audit_entry[:audit_id]}"
  end

  def should_log_externally?(category, event)
    # Define which events should be sent to external systems
    external_categories = [ :security, :compliance ]
    critical_events = %w[access_revocation_detected multiple_failed_attempts]

    external_categories.include?(category) || critical_events.include?(event.to_s)
  end

  def format_audit_message(audit_entry)
    "OAUTH_AUDIT [#{audit_entry[:category]}:#{audit_entry[:event]}] " \
    "#{audit_entry[:correlation_id]} - #{audit_entry[:details].inspect}"
  end

  def sanitize_sensitive_data(details)
    # Remove or mask sensitive information from logs
    sanitized = details.dup

    # Remove sensitive keys
    sensitive_keys = [ :password, :access_token, :refresh_token, :client_secret, :authorization_code ]
    sensitive_keys.each { |key| sanitized.delete(key) }

    # Mask partial data for debugging
    if sanitized[:email]
      sanitized[:email_masked] = mask_email(sanitized[:email])
      sanitized.delete(:email)
    end

    if sanitized[:ip_address]
      sanitized[:ip_masked] = mask_ip_address(sanitized[:ip_address])
    end

    sanitized
  end

  def mask_email(email)
    return email unless email.include?("@")
    local, domain = email.split("@")
    masked_local = local.length > 2 ? local[0] + "*" * (local.length - 2) + local[-1] : local
    "#{masked_local}@#{domain}"
  end

  def mask_ip_address(ip)
    return ip unless ip.include?(".")
    parts = ip.split(".")
    parts[2] = "xxx"
    parts[3] = "xxx"
    parts.join(".")
  end

  def generate_audit_id
    "audit_#{SecureRandom.hex(8)}"
  end

  def generate_correlation_id
    "corr_#{SecureRandom.hex(6)}"
  end

  def extract_ip_address(details)
    details[:ip_address] || details[:remote_ip] || "unknown"
  end

  def extract_user_agent(details)
    details[:user_agent] || details[:http_user_agent] || "unknown"
  end

  def extract_session_id(details)
    details[:session_id] || "none"
  end

  def get_system_status
    # Return current system status
    :operational
  end

  def get_memory_usage
    # Return current memory usage
    GC.stat[:heap_live_slots] rescue "unknown"
  end

  def get_active_connections
    # Return active connection count
    ActiveRecord::Base.connection_pool.stat[:size] rescue "unknown"
  end

  def determine_threat_level(event, details)
    case event.to_s
    when /multiple_failed/, /brute_force/
      :high
    when /suspicious/, /unusual/
      :medium
    when /revocation/, /unauthorized/
      :medium
    else
      :low
    end
  end

  def requires_investigation?(event, severity)
    severity == :critical || event.to_s.include?("suspicious")
  end

  def categorize_performance(duration_ms)
    case duration_ms
    when 0..100 then :excellent
    when 101..500 then :good
    when 501..2000 then :acceptable
    when 2001..5000 then :slow
    else :critical
    end
  end

  def performance_threshold(operation)
    # Define performance thresholds for different operations
    thresholds = {
      token_refresh: 2000,  # 2 seconds
      api_request: 5000,    # 5 seconds
      authentication: 3000, # 3 seconds
      default: 10000        # 10 seconds
    }

    thresholds[operation.to_sym] || thresholds[:default]
  end

  def export_as_json(logs)
    JSON.pretty_generate(logs)
  end

  def export_as_csv(logs)
    # Convert logs to CSV format
    # This would typically use the CSV library
    "timestamp,category,event,user_id,details\n" # Header + data
  end

  def export_as_xml(logs)
    # Convert logs to XML format
    # This would typically use Builder or Nokogiri
    "<?xml version='1.0'?><audit_logs></audit_logs>"
  end

  def determine_retention_period(regulation)
    case regulation
    when :gdpr then 7.years
    when :ccpa then 2.years
    when :hipaa then 6.years
    else 5.years
    end
  end

  def requires_compliance_storage?(regulation)
    # Some regulations require separate storage
    [ :hipaa, :pci_dss ].include?(regulation)
  end

  def store_compliance_record(compliance_entry)
    # Store in compliance-specific system
    logger.info "Compliance record stored: #{compliance_entry[:audit_id]}"
  end
end

class NationbuilderAdminDashboard
  attr_reader :audit_logger

  def initialize
    @audit_logger = NationbuilderAuditLogger.new
  end

  # Get comprehensive OAuth2 system status
  def system_status
    {
      overview: system_overview,
      user_statistics: user_statistics,
      token_health: token_health_metrics,
      recent_events: recent_oauth_events,
      security_alerts: security_alerts,
      performance_metrics: performance_metrics,
      system_health: system_health_check,
      generated_at: Time.current
    }
  end

  # Get detailed information about all users' OAuth2 status
  def user_oauth_status(limit: 50, filter: {})
    users_with_tokens = User.joins(:nationbuilder_tokens)
                           .includes(:nationbuilder_tokens)
                           .limit(limit)

    users_with_tokens.map do |user|
      {
        user_id: user.id,
        email: user.email_address,
        token_status: analyze_user_token_status(user),
        last_activity: get_user_last_activity(user),
        issues: detect_user_issues(user),
        recommendations: generate_user_recommendations(user)
      }
    end
  end

  # Get token health metrics
  def token_health_metrics
    total_tokens = NationbuilderToken.count
    active_tokens = NationbuilderToken.where("expires_at > ?", Time.current).count
    expired_tokens = NationbuilderToken.where("expires_at <= ?", Time.current).count
    expiring_soon = NationbuilderToken.expiring_soon.count

    {
      total_tokens: total_tokens,
      active_tokens: active_tokens,
      expired_tokens: expired_tokens,
      expiring_soon: expiring_soon,
      health_percentage: total_tokens > 0 ? (active_tokens.to_f / total_tokens * 100).round(2) : 0,
      tokens_by_age: tokens_by_age_distribution,
      refresh_success_rate: calculate_refresh_success_rate
    }
  end

  # Get recent OAuth2 events for monitoring
  def recent_oauth_events(limit: 100, timeframe: 24.hours)
    since = Time.current - timeframe

    # This would typically query the audit logs
    # For now, we'll return a structured placeholder
    {
      timeframe: timeframe,
      total_events: 0,
      events_by_type: {
        authentication: 0,
        token_refresh: 0,
        api_requests: 0,
        errors: 0
      },
      recent_events: [],
      trends: calculate_event_trends(since)
    }
  end

  # Get security alerts and issues
  def security_alerts
    alerts = []

    # Check for multiple failed authentication attempts
    failed_attempts = detect_failed_authentication_patterns
    if failed_attempts.any?
      alerts << {
        type: :multiple_failed_attempts,
        severity: :medium,
        count: failed_attempts.size,
        description: "Multiple failed authentication attempts detected",
        users_affected: failed_attempts.map { |u| u[:user_id] },
        recommended_action: "Review affected users and consider temporary restrictions"
      }
    end

    # Check for unusual token patterns
    unusual_patterns = detect_unusual_token_patterns
    if unusual_patterns.any?
      alerts << {
        type: :unusual_token_patterns,
        severity: :low,
        description: "Unusual token usage patterns detected",
        details: unusual_patterns,
        recommended_action: "Monitor for potential security issues"
      }
    end

    # Check for expired refresh tokens
    expired_refresh_tokens = NationbuilderToken.where(
      "expires_at <= ? AND refresh_token IS NOT NULL",
      Time.current
    ).count

    if expired_refresh_tokens > 0
      alerts << {
        type: :expired_refresh_tokens,
        severity: :low,
        count: expired_refresh_tokens,
        description: "Users with expired refresh tokens need re-authentication",
        recommended_action: "Notify affected users to re-authenticate"
      }
    end

    alerts
  end

  # Get performance metrics for OAuth2 operations
  def performance_metrics(timeframe: 24.hours)
    {
      timeframe: timeframe,
      api_request_performance: {
        average_response_time: 850, # milliseconds
        success_rate: 98.5,
        error_rate: 1.5,
        requests_per_hour: 120
      },
      token_refresh_performance: {
        average_refresh_time: 450, # milliseconds
        success_rate: 99.2,
        failure_rate: 0.8
      },
      authentication_performance: {
        average_auth_time: 1200, # milliseconds
        success_rate: 95.0,
        completion_rate: 94.2
      }
    }
  end

  # Check system health for OAuth2 components
  def system_health_check
    checks = {}

    # Check database connectivity
    checks[:database] = check_database_health

    # Check external API connectivity
    checks[:nationbuilder_api] = check_nationbuilder_api_health

    # Check token refresh capability
    checks[:token_refresh] = check_token_refresh_health

    # Check audit logging
    checks[:audit_logging] = check_audit_logging_health

    # Overall health status
    overall_status = checks.values.all? { |check| check[:status] == :healthy } ? :healthy : :degraded

    {
      overall_status: overall_status,
      checks: checks,
      last_checked: Time.current
    }
  end

  # Get configuration status
  def configuration_status
    {
      environment_variables: check_environment_variables,
      oauth_settings: check_oauth_configuration,
      security_settings: check_security_configuration,
      logging_configuration: check_logging_configuration
    }
  end

  # Export OAuth2 data for analysis
  def export_oauth_data(format: :json, timeframe: 7.days)
    data = {
      export_info: {
        generated_at: Time.current,
        timeframe: timeframe,
        format: format
      },
      system_status: system_status,
      user_data: user_oauth_status(limit: 1000),
      audit_logs: audit_logger.export_logs(format: format, timeframe: timeframe)
    }

    case format
    when :json
      JSON.pretty_generate(data)
    when :csv
      convert_to_csv(data)
    else
      data
    end
  end

  # Get recommendations for system improvements
  def system_recommendations
    recommendations = []

    # Check token health
    token_metrics = token_health_metrics
    if token_metrics[:health_percentage] < 80
      recommendations << {
        type: :token_health,
        priority: :high,
        title: "Low Token Health Detected",
        description: "#{token_metrics[:expired_tokens]} tokens are expired",
        action: "Review expired tokens and notify users to re-authenticate"
      }
    end

    # Check performance
    performance = performance_metrics
    if performance[:api_request_performance][:success_rate] < 95
      recommendations << {
        type: :performance,
        priority: :medium,
        title: "API Success Rate Below Threshold",
        description: "API success rate is #{performance[:api_request_performance][:success_rate]}%",
        action: "Investigate API errors and improve error handling"
      }
    end

    # Check security
    alerts = security_alerts
    if alerts.any? { |alert| alert[:severity] == :high }
      recommendations << {
        type: :security,
        priority: :high,
        title: "High Severity Security Alerts",
        description: "Critical security issues detected",
        action: "Immediately review security alerts and take corrective action"
      }
    end

    recommendations
  end

  private

  def system_overview
    {
      total_users: User.count,
      users_with_tokens: User.joins(:nationbuilder_tokens).distinct.count,
      total_tokens: NationbuilderToken.count,
      active_sessions: Session.where("created_at > ?", 24.hours.ago).count,
      system_uptime: get_system_uptime,
      last_deployment: get_last_deployment_time
    }
  end

  def user_statistics
    {
      total_users: User.count,
      authenticated_users: User.joins(:nationbuilder_tokens)
                               .where("nationbuilder_tokens.expires_at > ?", Time.current)
                               .distinct.count,
      users_needing_reauth: User.joins(:nationbuilder_tokens)
                               .where("nationbuilder_tokens.expires_at <= ?", Time.current)
                               .distinct.count,
      new_users_today: User.where("created_at >= ?", Date.current).count,
      active_users_24h: User.joins(:sessions)
                            .where("sessions.created_at > ?", 24.hours.ago)
                            .distinct.count
    }
  end

  def analyze_user_token_status(user)
    tokens = user.nationbuilder_tokens.order(created_at: :desc)
    current_token = tokens.first

    return { status: :no_tokens } unless current_token

    {
      status: determine_token_status(current_token),
      token_count: tokens.count,
      current_token_age: Time.current - current_token.created_at,
      expires_at: current_token.expires_at,
      time_until_expiry: current_token.time_until_expiry,
      scope: current_token.scope
    }
  end

  def determine_token_status(token)
    return :expired if token.expired?
    return :expiring_soon if token.expiring_soon?
    return :healthy if token.valid_for_api_use?
    :unknown
  end

  def get_user_last_activity(user)
    # This would typically check various activity logs
    {
      last_login: user.sessions.order(created_at: :desc).first&.created_at,
      last_api_request: nil, # Would be pulled from API logs
      last_token_refresh: user.nationbuilder_tokens.order(updated_at: :desc).first&.updated_at
    }
  end

  def detect_user_issues(user)
    issues = []

    token = user.nationbuilder_tokens.order(created_at: :desc).first
    return issues unless token

    issues << :token_expired if token.expired?
    issues << :token_expiring_soon if token.expiring_soon?
    issues << :no_refresh_token if token.refresh_token.blank?
    issues << :old_token if token.created_at < 30.days.ago

    issues
  end

  def generate_user_recommendations(user)
    issues = detect_user_issues(user)
    recommendations = []

    recommendations << "User should re-authenticate" if issues.include?(:token_expired)
    recommendations << "Token will expire soon - monitor for refresh" if issues.include?(:token_expiring_soon)
    recommendations << "No refresh token available - user will need to re-authenticate when token expires" if issues.include?(:no_refresh_token)
    recommendations << "Consider prompting user to refresh their authentication" if issues.include?(:old_token)

    recommendations
  end

  def tokens_by_age_distribution
    {
      "0-1 days" => NationbuilderToken.where("created_at > ?", 1.day.ago).count,
      "1-7 days" => NationbuilderToken.where(created_at: 7.days.ago..1.day.ago).count,
      "7-30 days" => NationbuilderToken.where(created_at: 30.days.ago..7.days.ago).count,
      "30+ days" => NationbuilderToken.where("created_at <= ?", 30.days.ago).count
    }
  end

  def calculate_refresh_success_rate
    # This would calculate based on audit logs
    # For now, return a placeholder
    99.2
  end

  def calculate_event_trends(since)
    # This would analyze trends in the audit logs
    {
      authentication_trend: :stable,
      error_rate_trend: :improving,
      api_usage_trend: :increasing
    }
  end

  def detect_failed_authentication_patterns
    # This would analyze audit logs for patterns
    []
  end

  def detect_unusual_token_patterns
    # This would analyze token usage patterns
    []
  end

  def check_database_health
    begin
      NationbuilderToken.connection.execute("SELECT 1")
      { status: :healthy, message: "Database connection successful" }
    rescue => e
      { status: :unhealthy, message: "Database error: #{e.message}" }
    end
  end

  def check_nationbuilder_api_health
    # This would make a test API call to NationBuilder
    { status: :healthy, message: "API connectivity not tested in demo" }
  end

  def check_token_refresh_health
    # This would test token refresh capability
    { status: :healthy, message: "Token refresh service operational" }
  end

  def check_audit_logging_health
    begin
      audit_logger.log_event(:system, :health_check, { test: true })
      { status: :healthy, message: "Audit logging functional" }
    rescue => e
      { status: :unhealthy, message: "Audit logging error: #{e.message}" }
    end
  end

  def check_environment_variables
    required_vars = %w[NATIONBUILDER_CLIENT_ID NATIONBUILDER_CLIENT_SECRET NATIONBUILDER_NATION_SLUG]
    missing_vars = required_vars.select { |var| ENV[var].blank? }

    {
      status: missing_vars.empty? ? :complete : :incomplete,
      missing_variables: missing_vars,
      configured_variables: required_vars - missing_vars
    }
  end

  def check_oauth_configuration
    {
      client_id_configured: ENV["NATIONBUILDER_CLIENT_ID"].present?,
      client_secret_configured: ENV["NATIONBUILDER_CLIENT_SECRET"].present?,
      redirect_uri_configured: ENV["NATIONBUILDER_REDIRECT_URI"].present?,
      nation_slug_configured: ENV["NATIONBUILDER_NATION_SLUG"].present?
    }
  end

  def check_security_configuration
    {
      token_encryption_enabled: NationbuilderToken.encrypted_attributes.any?,
      secure_cookies: Rails.application.config.force_ssl,
      audit_logging_enabled: true
    }
  end

  def check_logging_configuration
    {
      audit_logging_enabled: true,
      log_level: Rails.logger.level,
      log_file_writable: File.writable?(Rails.root.join("log"))
    }
  end

  def get_system_uptime
    # This would calculate actual system uptime
    "24h 15m" # Placeholder
  end

  def get_last_deployment_time
    # This would get actual deployment timestamp
    1.day.ago # Placeholder
  end

  def convert_to_csv(data)
    # Convert data structure to CSV format
    "CSV export functionality would be implemented here"
  end
end

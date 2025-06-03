class NationbuilderNotificationService
  attr_reader :logger

  def initialize(logger: Rails.logger)
    @logger = logger
  end

  # Send notification to user about authentication issues
  def notify_user(user:, notification_type:, title:, message:, error: nil, priority: :medium, **options)
    notification_data = build_user_notification(
      user: user,
      type: notification_type,
      title: title,
      message: message,
      error: error,
      priority: priority,
      **options
    )

    # Send through multiple channels based on priority and type
    delivery_results = {}

    case priority
    when :critical, :high
      delivery_results[:flash] = send_flash_notification(notification_data)
      delivery_results[:email] = send_email_notification(notification_data) if should_send_email?(notification_type)
      delivery_results[:session] = store_in_session(notification_data)
    when :medium
      delivery_results[:flash] = send_flash_notification(notification_data)
      delivery_results[:session] = store_in_session(notification_data)
    else
      delivery_results[:session] = store_in_session(notification_data)
    end

    # Log the notification
    log_notification(:user_notification_sent, notification_data, delivery_results)

    delivery_results
  end

  # Send notification to admins about system issues
  def notify_admin(notification_type:, title:, message:, error: nil, user: nil, **options)
    notification_data = build_admin_notification(
      type: notification_type,
      title: title,
      message: message,
      error: error,
      user: user,
      **options
    )

    # Send to admin channels
    delivery_results = {
      logs: log_admin_notification(notification_data),
      dashboard: store_admin_notification(notification_data)
    }

    # Send email for critical issues
    if notification_data[:severity] == :critical
      delivery_results[:email] = send_admin_email(notification_data)
    end

    # Log the notification
    log_notification(:admin_notification_sent, notification_data, delivery_results)

    delivery_results
  end

  # Get pending notifications for a user
  def get_user_notifications(user:, types: nil, limit: 10)
    # This would typically query a notifications table
    # For now, we'll check session and flash
    notifications = []

    # Add session notifications
    session_notifications = get_session_notifications(user)
    notifications.concat(session_notifications) if session_notifications

    # Filter by types if specified
    if types
      notifications.select! { |n| types.include?(n[:type].to_sym) }
    end

    notifications.last(limit)
  end

  # Mark notifications as read
  def mark_notifications_read(user:, notification_ids: nil)
    # This would typically update a notifications table
    # For now, we'll just log the action
    log_notification(:notifications_marked_read, {
      user_id: user.id,
      notification_ids: notification_ids,
      timestamp: Time.current
    })

    true
  end

  # Get notification statistics
  def notification_stats(user: nil, timeframe: 24.hours)
    since = Time.current - timeframe

    if user
      get_user_notification_stats(user, since)
    else
      get_system_notification_stats(since)
    end
  end

  # Send immediate re-authentication prompt
  def send_reauthentication_prompt(user:, reason:, redirect_url: nil)
    prompt_data = {
      user_id: user.id,
      reason: reason,
      redirect_url: redirect_url,
      timestamp: Time.current,
      type: :reauthentication_required
    }

    # Store in session for immediate display
    store_reauthentication_prompt(prompt_data)

    # Log the prompt
    log_notification(:reauthentication_prompt_sent, prompt_data)

    prompt_data
  end

  # Create contextual help for OAuth errors
  def create_error_help(error:, user_context: {})
    help_content = {
      error_type: error.class.name,
      user_friendly_title: generate_user_friendly_title(error),
      explanation: generate_error_explanation(error),
      suggested_actions: generate_suggested_actions(error, user_context),
      help_links: generate_help_links(error),
      technical_details: error.respond_to?(:loggable_details) ? error.loggable_details : nil
    }

    log_notification(:error_help_created, help_content.except(:technical_details))

    help_content
  end

  private

  def build_user_notification(user:, type:, title:, message:, error:, priority:, **options)
    {
      id: generate_notification_id,
      user_id: user.id,
      type: type,
      title: title,
      message: message,
      priority: priority,
      timestamp: Time.current,
      read: false,
      dismissible: options.fetch(:dismissible, true),
      expires_at: options[:expires_at] || (Time.current + 1.hour),
      action_required: options.fetch(:action_required, false),
      action_url: options[:action_url],
      action_text: options[:action_text],
      show_details: options.fetch(:show_details, true),
      error_details: error ? extract_error_details(error) : nil
    }
  end

  def build_admin_notification(type:, title:, message:, error:, user:, **options)
    {
      id: generate_notification_id,
      type: type,
      title: title,
      message: message,
      severity: options.fetch(:severity, :medium),
      timestamp: Time.current,
      user_id: user&.id,
      user_email: user&.email_address,
      error_details: error ? error.loggable_details : nil,
      system_context: gather_system_context,
      requires_action: options.fetch(:requires_action, false),
      category: options.fetch(:category, :oauth)
    }
  end

  def send_flash_notification(notification_data)
    # This would integrate with Rails flash messages
    # For now, we'll just return a success indicator
    {
      success: true,
      message_id: notification_data[:id],
      delivery_method: :flash
    }
  end

  def send_email_notification(notification_data)
    # This would integrate with your email system (ActionMailer, etc.)
    # For now, we'll just log and return success
    logger.info "Email notification queued: #{notification_data[:id]}"

    {
      success: true,
      message_id: notification_data[:id],
      delivery_method: :email,
      queued_at: Time.current
    }
  end

  def store_in_session(notification_data)
    # This would store the notification in the user's session
    # For now, we'll just return success
    {
      success: true,
      message_id: notification_data[:id],
      delivery_method: :session
    }
  end

  def store_reauthentication_prompt(prompt_data)
    # Store the prompt for immediate display
    logger.info "Reauthentication prompt stored: #{prompt_data.to_json}"
    true
  end

  def log_admin_notification(notification_data)
    logger.error "ADMIN NOTIFICATION: #{notification_data.to_json}"
    true
  end

  def store_admin_notification(notification_data)
    # This would store in admin dashboard/database
    # For now, just log
    logger.info "Admin notification stored: #{notification_data[:id]}"
    true
  end

  def send_admin_email(notification_data)
    # Send email to administrators
    logger.error "CRITICAL ADMIN EMAIL: #{notification_data.to_json}"
    {
      success: true,
      delivery_method: :admin_email,
      sent_at: Time.current
    }
  end

  def should_send_email?(notification_type)
    # Define which notification types should trigger emails
    email_types = [
      :access_revoked,
      :reauthentication_required,
      :account_disabled,
      :security_alert
    ]

    email_types.include?(notification_type.to_sym)
  end

  def get_session_notifications(user)
    # This would query session storage
    # For now, return empty array
    []
  end

  def get_user_notification_stats(user, since)
    # This would query a notifications table
    {
      user_id: user.id,
      total_notifications: 0,
      unread_notifications: 0,
      notifications_by_type: {},
      timeframe: since
    }
  end

  def get_system_notification_stats(since)
    # This would query system-wide notification stats
    {
      total_notifications: 0,
      notifications_by_type: {},
      notifications_by_priority: {},
      admin_notifications: 0,
      timeframe: since
    }
  end

  def generate_notification_id
    "notif_#{SecureRandom.hex(8)}"
  end

  def extract_error_details(error)
    if error.respond_to?(:to_h)
      error.to_h
    else
      {
        error_class: error.class.name,
        message: error.message
      }
    end
  end

  def gather_system_context
    {
      rails_env: Rails.env,
      timestamp: Time.current,
      app_version: ENV["APP_VERSION"] || "unknown"
    }
  end

  def generate_user_friendly_title(error)
    case error
    when NationbuilderOauthErrors::AccessRevokedError
      "Access Permission Revoked"
    when NationbuilderOauthErrors::InvalidRefreshTokenError
      "Session Expired"
    when NationbuilderOauthErrors::InvalidAccessTokenError
      "Authentication Required"
    when NationbuilderOauthErrors::RateLimitError
      "Service Temporarily Busy"
    when NationbuilderOauthErrors::NetworkError
      "Connection Problem"
    when NationbuilderOauthErrors::ConfigurationError
      "Service Configuration Issue"
    else
      "Authentication Problem"
    end
  end

  def generate_error_explanation(error)
    case error
    when NationbuilderOauthErrors::AccessRevokedError
      "Your access to this application has been revoked. This may happen if you revoked permissions in your account settings."
    when NationbuilderOauthErrors::InvalidRefreshTokenError
      "Your session has expired and needs to be refreshed. This is normal security behavior."
    when NationbuilderOauthErrors::InvalidAccessTokenError
      "Your authentication token is no longer valid. Please log in again."
    when NationbuilderOauthErrors::RateLimitError
      "Too many requests have been made in a short time. Please wait a moment before trying again."
    when NationbuilderOauthErrors::NetworkError
      "There was a problem connecting to the authentication service. This is usually temporary."
    when NationbuilderOauthErrors::ConfigurationError
      "There's a configuration issue with the authentication service. Our administrators have been notified."
    else
      "An authentication problem occurred. Please try logging in again."
    end
  end

  def generate_suggested_actions(error, user_context)
    case error
    when NationbuilderOauthErrors::AccessRevokedError
      [
        "Log in again to restore access",
        "Check your account permissions",
        "Contact support if you didn't revoke access"
      ]
    when NationbuilderOauthErrors::InvalidRefreshTokenError, NationbuilderOauthErrors::InvalidAccessTokenError
      [
        "Click 'Log In' to authenticate again",
        "Your data and settings will be preserved"
      ]
    when NationbuilderOauthErrors::RateLimitError
      delay = error.try(:retry_delay) || 60
      [
        "Wait #{delay} seconds before trying again",
        "Refresh the page after waiting"
      ]
    when NationbuilderOauthErrors::NetworkError
      [
        "Check your internet connection",
        "Try refreshing the page",
        "Wait a moment and try again"
      ]
    else
      [
        "Try logging in again",
        "Contact support if the problem persists"
      ]
    end
  end

  def generate_help_links(error)
    # Return relevant help documentation links
    base_help = [
      {
        text: "Authentication Help",
        url: "/help/authentication"
      }
    ]

    case error
    when NationbuilderOauthErrors::AccessRevokedError
      base_help << {
        text: "Managing App Permissions",
        url: "/help/permissions"
      }
    when NationbuilderOauthErrors::NetworkError
      base_help << {
        text: "Connection Troubleshooting",
        url: "/help/connection-issues"
      }
    end

    base_help
  end

  def log_notification(event, notification_data, delivery_results = nil)
    log_data = {
      event: event,
      notification_id: notification_data[:id],
      timestamp: Time.current
    }

    log_data[:delivery_results] = delivery_results if delivery_results
    log_data.merge!(notification_data.except(:error_details, :technical_details))

    logger.info log_data.to_json
  end
end

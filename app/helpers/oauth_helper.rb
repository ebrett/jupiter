module OauthHelper
  def oauth_error_flash(error_type, message, title = nil, can_retry: true)
    title ||= default_oauth_error_title(error_type)
    
    # Store error data in flash for JavaScript to pick up
    flash[:alert] = message
    flash[:oauth_error_data] = {
      title: title,
      message: message,
      error_type: error_type,
      can_retry: can_retry
    }.to_json
  end

  def oauth_status_badge(user)
    return content_tag(:span, "No OAuth", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800") unless user.nationbuilder_tokens.any?

    token = user.nationbuilder_tokens.order(created_at: :desc).first
    
    if token.valid_for_api_use?
      content_tag(:span, "Connected", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800")
    elsif token.needs_refresh?
      content_tag(:span, "Refresh Needed", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800")
    else
      content_tag(:span, "Disconnected", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800")
    end
  end

  def oauth_connection_status_message(user)
    return "Connect your NationBuilder account to access additional features." unless user.nationbuilder_tokens.any?

    token = user.nationbuilder_tokens.order(created_at: :desc).first
    
    if token.valid_for_api_use?
      "Your NationBuilder account is connected and working properly."
    elsif token.needs_refresh?
      "Your NationBuilder connection needs to be refreshed. This happens automatically when you use NationBuilder features."
    else
      "Your NationBuilder connection has expired. Please reconnect your account."
    end
  end

  def oauth_retry_link(error_type, text = "Try Again", css_class = "text-blue-600 hover:text-blue-500")
    case error_type.to_s
    when 'authentication_error', 'token_expired', 'permissions_error'
      link_to text, "/auth/nationbuilder", class: css_class
    when 'network_error'
      link_to text, request.fullpath, class: css_class
    else
      link_to text, "/auth/nationbuilder", class: css_class
    end
  end

  def oauth_error_icon(error_type)
    case error_type.to_s
    when 'authentication_error'
      content_tag(:div, class: "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100") do
        content_tag(:svg, class: "h-6 w-6 text-red-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M12 15v2m-6 0h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z")
        end
      end
    when 'network_error'
      content_tag(:div, class: "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-yellow-100") do
        content_tag(:svg, class: "h-6 w-6 text-yellow-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
        end
      end
    when 'permissions_error'
      content_tag(:div, class: "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-orange-100") do
        content_tag(:svg, class: "h-6 w-6 text-orange-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
        end
      end
    else
      content_tag(:div, class: "mx-auto flex items-center justify-center h-12 w-12 rounded-full bg-red-100") do
        content_tag(:svg, class: "h-6 w-6 text-red-600", fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
          content_tag(:path, "", "stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.314 15.5c-.77.833.192 2.5 1.732 2.5z")
        end
      end
    end
  end

  private

  def default_oauth_error_title(error_type)
    case error_type.to_s
    when 'authentication_error'
      "Authentication Failed"
    when 'network_error'
      "Connection Problem"
    when 'token_expired'
      "Session Expired"
    when 'permissions_error'
      "Permission Denied"
    when 'rate_limit_error'
      "Too Many Requests"
    when 'server_error'
      "Service Unavailable"
    else
      "Authentication Issue"
    end
  end
end
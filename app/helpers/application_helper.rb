module ApplicationHelper
  def render_flash_messages
    return unless flash.any?

    safe_join(
      flash.map do |type, message|
        # Skip special flash keys that aren't meant to be displayed
        next if type.to_s == 'oauth_error_data'
        
        variant = case type.to_sym
        when :notice
                    :success
        when :alert
                    :error
        when :warning
                    :warning
        when :info
                    :info
        else
                    :info
        end

        render Catalyst::NotificationComponent.new(
          message: message,
          variant: variant,
          dismissible: true
        )
      end.compact
    )
  end

  def user_initials
    return "" unless authenticated? && Current.user

    if Current.user.first_name.present?
      Catalyst::AvatarComponent.initials_from_name("#{Current.user.first_name} #{Current.user.last_name}")
    else
      Current.user.email_address.first.upcase
    end
  end

  def user_display_name
    return "" unless authenticated? && Current.user

    if Current.user.first_name.present?
      "#{Current.user.first_name} #{Current.user.last_name}".strip
    else
      Current.user.email_address.split("@").first.titleize
    end
  end

  def nation_display_name
    slug = ENV["NATIONBUILDER_NATION_SLUG"]
    return "NationBuilder" if slug.blank?

    # Convert slug to display name (e.g., "democrats-abroad" -> "Democrats Abroad")
    slug.split("-").map(&:capitalize).join(" ")
  end
end

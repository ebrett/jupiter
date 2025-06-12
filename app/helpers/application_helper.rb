module ApplicationHelper
  def render_flash_messages
    return unless flash.any?

    safe_join(
      flash.map do |type, message|
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
      end
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
end

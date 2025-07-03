class ApplicationController < ActionController::Base
  include Authentication
  include OauthHelper
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  helper_method :current_user, :show_sidebar?

  def current_user
    Current.user
  end

  # Helper method to determine if we should show the sidebar
  def show_sidebar?
    # Hide sidebar on authentication pages
    return false if controller_name == "sessions"
    return false if controller_name == "users" && action_name == "new"
    return false if controller_name == "passwords"
    return false if controller_name == "registrations"

    true
  end

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end

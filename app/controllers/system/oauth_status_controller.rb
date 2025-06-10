class System::OauthStatusController < ApplicationController
  before_action :require_system_administrator!

  def index
    # Existing logic for showing OAuth status
    render "system/oauth_status"
  end

  def export
    # Existing logic for exporting OAuth data
    # ...
  end

  private

  def require_system_administrator!
    unless current_user&.has_role?(:system_administrator)
      redirect_to root_path, alert: "You are not authorized to access this area."
    end
  end
end

class Admin::BaseController < ApplicationController
  before_action :require_authentication
  before_action :require_admin_access

  layout "admin"

  private

  def current_user
    Current.user
  end

  def require_admin_access
    unless Current.user&.admin?
      redirect_to root_path, alert: "You are not authorized to access the admin area."
    end
  end
end

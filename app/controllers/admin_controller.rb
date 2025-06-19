class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_access

  private

  def require_admin_access
    unless current_user&.admin?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Access denied. Admin privileges required." }
        format.json { render json: { error: "Access denied" }, status: :forbidden }
      end
    end
  end
end

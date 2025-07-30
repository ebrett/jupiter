class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_access

  def index
    @pending_requests = ReimbursementRequest.submitted.count
    @under_review_requests = ReimbursementRequest.under_review.count
    @recent_requests = ReimbursementRequest.includes(:user).recent.limit(5)
  end

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

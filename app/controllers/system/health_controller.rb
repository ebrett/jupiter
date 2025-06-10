class System::HealthController < ApplicationController
  before_action :require_system_administrator!

  def index
    # Existing logic for showing system health
    render 'system/health'
  end

  private

  def require_system_administrator!
    unless current_user&.has_role?(:system_administrator)
      redirect_to root_path, alert: 'You are not authorized to access this area.'
    end
  end
end 
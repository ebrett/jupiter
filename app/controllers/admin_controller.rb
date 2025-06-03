class AdminController < ApplicationController
  before_action :require_authentication

  def index
    @dashboard = NationbuilderAdminDashboard.new
    @system_status = @dashboard.system_status
    @recent_events = @dashboard.recent_oauth_events(limit: 10)
    @security_alerts = @dashboard.security_alerts
    @recommendations = @dashboard.system_recommendations
  end

  def oauth_status
    @dashboard = NationbuilderAdminDashboard.new

    respond_to do |format|
      format.html do
        @user_oauth_status = @dashboard.user_oauth_status(limit: 100)
        @token_health = @dashboard.token_health_metrics
        @performance_metrics = @dashboard.performance_metrics
      end

      format.json do
        render json: {
          system_status: @dashboard.system_status,
          user_oauth_status: @dashboard.user_oauth_status,
          token_health: @dashboard.token_health_metrics,
          performance_metrics: @dashboard.performance_metrics
        }
      end
    end
  end

  def system_health
    @dashboard = NationbuilderAdminDashboard.new
    @health_check = @dashboard.system_health_check
    @configuration_status = @dashboard.configuration_status

    respond_to do |format|
      format.html
      format.json do
        render json: {
          health_check: @health_check,
          configuration_status: @configuration_status
        }
      end
    end
  end

  def export_oauth_data
    @dashboard = NationbuilderAdminDashboard.new

    format = params[:format]&.to_sym || :json
    timeframe = params[:timeframe]&.to_i&.hours || 7.days

    exported_data = @dashboard.export_oauth_data(format: format, timeframe: timeframe)

    case format
    when :json
      send_data exported_data,
                filename: "oauth_data_#{Date.current}.json",
                type: "application/json"
    when :csv
      send_data exported_data,
                filename: "oauth_data_#{Date.current}.csv",
                type: "text/csv"
    else
      redirect_to admin_oauth_status_path, alert: "Invalid export format"
    end
  end

  private

  def require_admin_access
    # Add admin-specific authorization here
    # For now, just require authentication
    require_authentication
  end
end

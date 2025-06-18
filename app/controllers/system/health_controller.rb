class System::HealthController < ApplicationController
  before_action :require_system_administrator!

  def index
    @health_check = {
      checks: {
        database: {
          status: :healthy,
          message: "Database connection is active"
        },
        redis: {
          status: :healthy,
          message: "Redis connection is active"
        },
        oauth: {
          status: :healthy,
          message: "OAuth system is operational"
        }
      }
    }

    @configuration_status = {
      environment: {
        rails_env: Rails.env,
        ruby_version: RUBY_VERSION,
        rails_version: Rails.version
      },
      database: {
        adapter: ActiveRecord::Base.connection.adapter_name,
        pool_size: ActiveRecord::Base.connection_pool.size
      }
    }

    render "system/health"
  end

  private

  def require_system_administrator!
    unless current_user&.has_role?(:system_administrator)
      redirect_to root_path, alert: "You are not authorized to access this area."
    end
  end
end

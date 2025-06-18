class System::OauthStatusController < ApplicationController
  before_action :require_system_administrator!

  def index
    @token_health = {
      total_tokens: NationbuilderToken.count,
      active_tokens: NationbuilderToken.where("expires_at > ?", Time.current).count,
      expiring_soon: NationbuilderToken.where("expires_at > ? AND expires_at < ?", Time.current, 12.hours.from_now).count
    }

    @performance_metrics = {
      avg_response_time: 150, # This would be calculated from actual metrics
      success_rate: 99.9 # This would be calculated from actual metrics
    }

    # Filter users based on params
    users = User.all
    if params[:email].present?
      users = users.where("email_address ILIKE ?", "%#{params[:email]}%")
    end
    if params[:status].present?
      case params[:status]
      when "active"
        users = users.joins(:nationbuilder_tokens).where("nationbuilder_tokens.expires_at > ?", Time.current)
      when "expired"
        users = users.joins(:nationbuilder_tokens).where("nationbuilder_tokens.expires_at <= ?", Time.current)
      when "no_token"
        users = users.left_outer_joins(:nationbuilder_tokens).where(nationbuilder_tokens: { id: nil })
      end
    end

    @user_oauth_status = users.map do |user|
      token = user.nationbuilder_tokens.order(expires_at: :desc).first

      token_status = if token.nil?
        "No Token"
      elsif token.expires_at&.future?
        "Active"
      else
        "Expired"
      end

      {
        email: user.email_address,
        token_status: token_status,
        expires_at: token&.expires_at
      }
    end

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

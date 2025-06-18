module FeatureFlaggable
  extend ActiveSupport::Concern

  private

  def feature_enabled?(flag_name)
    FeatureFlagService.enabled?(flag_name, current_user)
  end

  def feature_disabled?(flag_name)
    FeatureFlagService.disabled?(flag_name, current_user)
  end

  def require_feature_flag(flag_name)
    unless feature_enabled?(flag_name)
      respond_to do |format|
        format.html { redirect_to root_path, alert: "This feature is not available." }
        format.json { render json: { error: "Feature not available" }, status: :forbidden }
      end
      return false
    end
    true
  end
end

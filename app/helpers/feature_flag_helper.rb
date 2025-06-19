module FeatureFlagHelper
  def feature_enabled?(flag_name)
    FeatureFlagService.enabled?(flag_name, current_user)
  end

  def feature_disabled?(flag_name)
    FeatureFlagService.disabled?(flag_name, current_user)
  end

  def if_feature_enabled(flag_name, &block)
    if feature_enabled?(flag_name)
      capture(&block) if block_given?
    end
  end

  def unless_feature_enabled(flag_name, &block)
    unless feature_enabled?(flag_name)
      capture(&block) if block_given?
    end
  end
end

class FeatureFlagService
  CACHE_TTL = 1.hour.freeze

  class << self
    def enabled?(flag_name, user = nil)
      new(flag_name, user).enabled?
    end

    def disabled?(flag_name, user = nil)
      !enabled?(flag_name, user)
    end

    def enable_for_user(flag_name, user)
      new(flag_name, user).enable_for_user
    end

    def disable_for_user(flag_name, user)
      new(flag_name, user).disable_for_user
    end

    def enable_for_role(flag_name, role_name)
      new(flag_name).enable_for_role(role_name)
    end

    def disable_for_role(flag_name, role_name)
      new(flag_name).disable_for_role(role_name)
    end

    def clear_cache(flag_name = nil)
      if flag_name
        Rails.cache.delete(cache_key(flag_name))
        Rails.cache.delete("#{cache_key(flag_name)}_assignments")
      else
        Rails.cache.delete_matched("feature_flag_*")
      end
    end

    private

    def cache_key(flag_name)
      "feature_flag_#{flag_name}"
    end
  end

  def initialize(flag_name, user = nil)
    @flag_name = flag_name.to_s
    @user = user
  end

  def enabled?
    return false unless feature_flag_exists?
    return false unless globally_enabled?
    return true if user_has_assignment? || user_has_role_assignment?

    false
  rescue => e
    Rails.logger.error "FeatureFlagService error for #{@flag_name}: #{e.message}"
    false # Fail-safe: disabled by default on errors
  end

  def enable_for_user
    return false unless @user
    return false unless feature_flag

    FeatureFlagAssignment.find_or_create_by(
      feature_flag: feature_flag,
      assignable: @user
    )

    clear_user_cache
    true
  rescue => e
    Rails.logger.error "Failed to enable #{@flag_name} for user #{@user.id}: #{e.message}"
    false
  end

  def disable_for_user
    return false unless @user
    return false unless feature_flag

    assignment = FeatureFlagAssignment.find_by(
      feature_flag: feature_flag,
      assignable: @user
    )

    assignment&.destroy
    clear_user_cache
    true
  rescue => e
    Rails.logger.error "Failed to disable #{@flag_name} for user #{@user.id}: #{e.message}"
    false
  end

  def enable_for_role(role_name)
    role = Role.find_by(name: role_name.to_s)
    return false unless role
    return false unless feature_flag

    FeatureFlagAssignment.find_or_create_by(
      feature_flag: feature_flag,
      assignable: role
    )

    clear_flag_cache
    true
  rescue => e
    Rails.logger.error "Failed to enable #{@flag_name} for role #{role_name}: #{e.message}"
    false
  end

  def disable_for_role(role_name)
    role = Role.find_by(name: role_name.to_s)
    return false unless role
    return false unless feature_flag

    assignment = FeatureFlagAssignment.find_by(
      feature_flag: feature_flag,
      assignable: role
    )

    assignment&.destroy
    clear_flag_cache
    true
  rescue => e
    Rails.logger.error "Failed to disable #{@flag_name} for role #{role_name}: #{e.message}"
    false
  end

  private

  attr_reader :flag_name, :user

  def feature_flag
    @feature_flag ||= FeatureFlag.find_by(name: @flag_name)
  end

  def feature_flag_exists?
    feature_flag.present?
  end

  def globally_enabled?
    Rails.cache.fetch(self.class.send(:cache_key, @flag_name), expires_in: CACHE_TTL) do
      feature_flag&.enabled? || false
    end
  end

  def user_has_assignment?
    return false unless @user

    assignments.any? { |assignment| assignment.assignable == @user }
  end

  def user_has_role_assignment?
    return false unless @user

    user_role_names = @user.role_names
    return false if user_role_names.empty?

    assignments.any? do |assignment|
      assignment.assignable_type == "Role" &&
      user_role_names.include?(assignment.assignable.name)
    end
  end

  def assignments
    @assignments ||= Rails.cache.fetch(
      "#{self.class.send(:cache_key, @flag_name)}_assignments",
      expires_in: CACHE_TTL
    ) do
      return [] unless feature_flag
      feature_flag.feature_flag_assignments.includes(:assignable).to_a
    end
  end

  def clear_user_cache
    clear_flag_cache
  end

  def clear_flag_cache
    self.class.clear_cache(@flag_name)
  end
end
